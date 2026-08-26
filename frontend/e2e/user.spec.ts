import {expect, test, type Page} from "@playwright/test";

/**
 * 사용자 도메인 사용자 흐름 — 목록·상세·삭제(단건/선택/취소).
 * API 는 page.route 로 가로채 가짜 응답을 준다. 껍데기는 ApiResponse(result/data/error) 그대로이고,
 * 필드는 src/user/types/user.ts 를 따른다(CONTRACT.md 에는 아직 이 엔드포인트가 기록되지 않았다).
 */

const USERS_URL = "**/api/v1/users";

type FakeUser = {
    id: number;
    name: string;
    email: string;
    createdAt: string;
    lastLoginAt: string | null;
};

const HONG: FakeUser = {
    id: 1, name: "홍길동", email: "hong@example.com",
    createdAt: "2026-08-14T10:00:00", lastLoginAt: "2026-08-20T09:30:00",
};
const LEE: FakeUser = {
    id: 2, name: "이몽룡", email: "lee@example.com",
    createdAt: "2026-08-15T11:00:00", lastLoginAt: null,
};

function apiSuccess(data: unknown): {result: string; data: unknown; error: null} {
    return {result: "SUCCESS", data, error: null};
}

function apiError(message: string): {result: string; data: null; error: {code: string; message: string; data: null}} {
    return {result: "ERROR", data: null, error: {code: "INTERNAL_ERROR", message, data: null}};
}

async function mockUserList(page: Page, users: () => FakeUser[]): Promise<void> {
    await page.route(USERS_URL, (route) => route.fulfill({json: apiSuccess(users())}));
}

test("목록이 사용자 이름·이메일·가입일과 함께 보인다", async ({page}) => {
    await mockUserList(page, () => [HONG, LEE]);

    await page.goto("/");

    await expect(page.getByText(HONG.name)).toBeVisible();
    await expect(page.getByText(HONG.email)).toBeVisible();
    await expect(page.getByText(LEE.name)).toBeVisible();
    // 한 번도 로그인하지 않은 사용자(lastLoginAt null)는 "-" 로 표시된다.
    await expect(page.getByText("마지막 로그인 -")).toBeVisible();
});

test("사용자가 없으면 빈 상태 문구가 보인다", async ({page}) => {
    await mockUserList(page, () => []);

    await page.goto("/");

    await expect(page.getByText("등록된 사용자가 없습니다.")).toBeVisible();
});

test("목록 로드가 실패하면 에러 알림과 다시 시도가 보이고, 다시 시도로 복구된다", async ({page}) => {
    let callCount = 0;
    await page.route(USERS_URL, (route) => {
        callCount += 1;
        if (callCount === 1) {
            return route.fulfill({status: 500, json: apiError("서버 오류")});
        }
        return route.fulfill({json: apiSuccess([HONG])});
    });
    // notify.error 는 웹에서 window.alert 라 핸들러를 먼저 걸어야 문구를 검증할 수 있다.
    page.once("dialog", (dialog) => {
        expect(dialog.message()).toContain("사용자 목록을 불러오지 못했습니다");
        return dialog.dismiss();
    });

    await page.goto("/");

    await expect(page.getByText("사용자 목록을 불러오지 못했습니다.")).toBeVisible();
    await page.getByRole("button", {name: "다시 시도"}).click();
    await expect(page.getByText(HONG.name)).toBeVisible();
});

test("행을 누르면 상세 모달이 열리고 닫기로 닫힌다", async ({page}) => {
    await mockUserList(page, () => [HONG]);
    await page.route(`${USERS_URL}/${HONG.id}`, (route) => route.fulfill({json: apiSuccess(HONG)}));

    await page.goto("/");
    await page.getByText(HONG.name).click();

    const detailModal = page.getByLabel("사용자 상세");
    await expect(detailModal.getByText(HONG.email)).toBeVisible();
    await expect(detailModal.getByText("가입일")).toBeVisible();

    await detailModal.getByRole("button", {name: "닫기"}).click();
    await expect(detailModal).toBeHidden();
});

test("단건 삭제 — 확인 팝업에서 삭제를 누르면 목록에서 사라진다", async ({page}) => {
    let users = [HONG, LEE];
    await mockUserList(page, () => users);
    await page.route(`${USERS_URL}/${HONG.id}`, (route) => {
        users = users.filter((eachUser) => eachUser.id !== HONG.id);
        return route.fulfill({json: apiSuccess(null)});
    });

    await page.goto("/");
    const hongRow = page.getByRole("button").filter({hasText: HONG.name});
    await hongRow.getByRole("button", {name: "삭제", exact: true}).click();

    await expect(page.getByText("이 사용자를 삭제할까요?")).toBeVisible();
    page.once("dialog", (dialog) => {
        expect(dialog.message()).toContain("삭제되었습니다");
        return dialog.dismiss();
    });
    await page.getByRole("button", {name: "삭제", exact: true}).last().click();

    await expect(page.getByText(HONG.name)).toBeHidden();
    await expect(page.getByText(LEE.name)).toBeVisible();
});

test("단건 삭제 — 확인 팝업에서 취소하면 목록이 그대로다", async ({page}) => {
    await mockUserList(page, () => [HONG]);

    await page.goto("/");
    const hongRow = page.getByRole("button").filter({hasText: HONG.name});
    await hongRow.getByRole("button", {name: "삭제", exact: true}).click();

    await expect(page.getByText("이 사용자를 삭제할까요?")).toBeVisible();
    await page.getByRole("button", {name: "취소"}).click();

    await expect(page.getByText("이 사용자를 삭제할까요?")).toBeHidden();
    await expect(page.getByText(HONG.name)).toBeVisible();
});

test("선택 삭제 — 체크한 사용자만 지워진다", async ({page}) => {
    let users = [HONG, LEE];
    await mockUserList(page, () => users);
    await page.route(`${USERS_URL}/bulk-delete`, (route) => {
        users = users.filter((eachUser) => eachUser.id !== HONG.id);
        return route.fulfill({json: apiSuccess(null)});
    });

    await page.goto("/");
    await page.getByRole("checkbox", {name: `${HONG.name} 선택`}).click();
    await expect(page.getByText("선택 1건")).toBeVisible();
    await page.getByRole("button", {name: "선택 삭제"}).click();

    await expect(page.getByText("선택한 사용자를 모두 삭제할까요?")).toBeVisible();
    page.once("dialog", (dialog) => {
        expect(dialog.message()).toContain("삭제되었습니다");
        return dialog.dismiss();
    });
    await page.getByRole("button", {name: "삭제", exact: true}).last().click();

    await expect(page.getByText(HONG.name)).toBeHidden();
    await expect(page.getByText(LEE.name)).toBeVisible();
    await expect(page.getByText("선택 0건")).toBeVisible();
});
