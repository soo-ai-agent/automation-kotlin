import type {Page} from "@playwright/test";

/**
 * 사용자 API 가짜 응답 — 두 spec 이 함께 쓴다.
 *
 * 필드 이름·타입은 `src/api/user.ts` 의 `User` 를 그대로 따른다.
 * (백엔드가 아직 이 엔드포인트를 만들지 않아 `CONTRACT.md` 에 기록이 없다 — 만들어지면 그쪽이 기준이 된다.)
 */
export type UserRow = {
    id: number;
    name: string;
    email: string;
    createdAt: string;
    lastLoginAt: string | null;
};

export const GILDONG: UserRow = {
    id: 1, name: "홍길동", email: "gildong@example.com",
    createdAt: "2026-08-14T10:00:00", lastLoginAt: null,
};

export const CHULSOO: UserRow = {
    id: 2, name: "김철수", email: "chulsoo@example.com",
    createdAt: "2026-08-15T11:30:00", lastLoginAt: "2026-08-20T09:00:00",
};

/** 서버 `ApiResponse<T>` 껍데기 — 빼먹으면 apiClient 가 실패로 처리한다. */
function success(data: unknown) {
    return {result: "SUCCESS", data: data, error: null};
}

function failure(code: string, message: string) {
    return {result: "ERROR", data: null, error: {code: code, message: message, data: null}};
}

/**
 * 목록·상세·삭제를 실제처럼 이어 준다 — 삭제하면 다음 목록 조회에서 빠진다.
 * 삭제 뒤 재조회까지 한 흐름으로 검증하려면 가짜 응답도 상태를 가져야 한다.
 */
export async function stubUserApi(page: Page, initialUsers: UserRow[]): Promise<void> {
    const users: UserRow[] = [...initialUsers];

    await page.route("**/api/v1/**", async (route) => {
        const request = route.request();
        const path: string = new URL(request.url()).pathname;

        if (path === "/api/v1/app-info") {
            await route.fulfill({json: success({serverVersion: "0.0.1"})});
            return;
        }

        const detailPath: RegExpMatchArray | null = path.match(/^\/api\/v1\/users\/(\d+)$/);
        if (detailPath) {
            await fulfillOneUser(route, users, Number(detailPath[1]), request.method());
            return;
        }

        if (path === "/api/v1/users") {
            // 여럿 삭제는 경로가 아니라 질의 문자열로 대상을 고른다 — DELETE /api/v1/users?ids=1,2
            if (request.method() === "DELETE") {
                const ids: string = new URL(request.url()).searchParams.get("ids") ?? "";
                for (const id of ids.split(",")) {
                    removeUser(users, Number(id));
                }
                await route.fulfill({status: 204, body: ""});
                return;
            }
            await route.fulfill({json: success(users)});
            return;
        }

        await route.fulfill({status: 404, json: failure("NOT_FOUND", "없는 경로입니다.")});
    });
}

/** 목록 조회만 실패시킨다. 나중에 등록한 route 가 먼저 잡히므로, 이 뒤에 성공 route 를 걸면 재시도가 성공한다. */
export async function stubUserListFailure(page: Page): Promise<void> {
    await page.route("**/api/v1/users", async (route) => {
        await route.fulfill({status: 500, json: failure("INTERNAL", "서버 오류입니다.")});
    });
}

async function fulfillOneUser(
    route: Parameters<Parameters<Page["route"]>[1]>[0],
    users: UserRow[],
    id: number,
    method: string,
): Promise<void> {
    if (method === "DELETE") {
        removeUser(users, id);
        // 본문 없는 삭제는 204 다(rules.md MUST). 클라이언트가 이걸 성공으로 받아야 한다.
        await route.fulfill({status: 204, body: ""});
        return;
    }
    const found: UserRow | undefined = users.find((eachUser: UserRow) => eachUser.id === id);
    if (!found) {
        await route.fulfill({status: 404, json: failure("NOT_FOUND", "없는 사용자입니다.")});
        return;
    }
    await route.fulfill({json: success(found)});
}

function removeUser(users: UserRow[], id: number): void {
    const index: number = users.findIndex((eachUser: UserRow) => eachUser.id === id);
    if (index >= 0) {
        users.splice(index, 1);
    }
}
