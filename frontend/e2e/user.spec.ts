import {expect, test, type Page} from "@playwright/test";
import {CHULSOO, GILDONG, stubUserApi, stubUserListFailure} from "./fixtures";

test("목록을 불러와 이름·이메일·마지막 로그인을 보여 준다", async ({page}) => {
    await stubUserApi(page, [GILDONG, CHULSOO]);

    await page.goto("/");

    await expect(page.getByText("홍길동")).toBeVisible();
    await expect(page.getByText("chulsoo@example.com")).toBeVisible();
    // 한 번도 로그인하지 않은 사용자는 lastLoginAt 이 null 이라 "-" 로 그려진다.
    await expect(page.getByRole("button", {name: /홍길동/})).toContainText("마지막 로그인 -");
});

test("사용자를 삭제하면 확인 팝업을 거쳐 목록에서 사라진다", async ({page}) => {
    await stubUserApi(page, [GILDONG, CHULSOO]);
    await page.goto("/");
    await expect(page.getByText("홍길동")).toBeVisible();

    await page.getByRole("button", {name: /홍길동/}).getByRole("button", {name: "삭제"}).click();
    await expect(page.getByText("이 사용자를 삭제할까요?")).toBeVisible();

    // 성공 알림은 아직 OS 대화상자다 — 누르기 전에 걸어 두지 않으면 자동으로 닫혀 검증이 사라진다.
    page.once("dialog", (dialog) => {
        expect(dialog.message()).toContain("삭제되었습니다");
        return dialog.dismiss();
    });
    await page.getByRole("button", {name: "삭제"}).last().click();

    await expect(page.getByText("홍길동")).toBeHidden();
    await expect(page.getByText("김철수")).toBeVisible();
});

test("삭제를 취소하면 목록이 그대로다", async ({page}) => {
    await stubUserApi(page, [GILDONG, CHULSOO]);
    await page.goto("/");
    await expect(page.getByText("홍길동")).toBeVisible();

    await page.getByRole("button", {name: /홍길동/}).getByRole("button", {name: "삭제"}).click();
    await page.getByRole("button", {name: "취소"}).click();

    await expect(page.getByText("이 사용자를 삭제할까요?")).toBeHidden();
    await expect(page.getByText("홍길동")).toBeVisible();
});

test("전체 선택 후 선택 삭제하면 목록이 빈다", async ({page}) => {
    await stubUserApi(page, [GILDONG, CHULSOO]);
    await page.goto("/");
    await expect(page.getByText("홍길동")).toBeVisible();

    await expect(page.getByRole("checkbox", {name: "홍길동 선택"})).not.toBeChecked();

    await page.getByRole("checkbox", {name: "전체 선택"}).click();
    await expect(page.getByText("선택 2건")).toBeVisible();
    // 체크 상태가 실제로 화면에 나가는지 본다 — accessibilityState 는 웹으로 안 나간다(aria-checked 를 쓴다)
    await expect(page.getByRole("checkbox", {name: "홍길동 선택"})).toBeChecked();

    await page.getByRole("button", {name: "선택 삭제"}).click();
    await expect(page.getByText("선택한 사용자를 모두 삭제할까요?")).toBeVisible();

    page.once("dialog", (dialog) => {
        expect(dialog.message()).toContain("삭제되었습니다");
        return dialog.dismiss();
    });
    await page.getByRole("button", {name: "삭제"}).last().click();

    await expect(page.getByText("등록된 사용자가 없습니다.")).toBeVisible();
});

test("아무도 선택하지 않고 선택 삭제를 누르면 안내만 뜬다", async ({page}) => {
    await stubUserApi(page, [GILDONG]);
    await page.goto("/");
    await expect(page.getByText("홍길동")).toBeVisible();

    page.once("dialog", (dialog) => {
        expect(dialog.message()).toContain("선택된 사용자가 없습니다");
        return dialog.dismiss();
    });
    await page.getByRole("button", {name: "선택 삭제"}).click();

    // 확인 팝업까지 가지 않고 멈춘다.
    await expect(page.getByText("선택한 사용자를 모두 삭제할까요?")).toBeHidden();
    await expect(page.getByText("홍길동")).toBeVisible();
});

test("사용자를 누르면 상세가 열리고 닫기로 닫힌다", async ({page}) => {
    await stubUserApi(page, [GILDONG]);
    await page.goto("/");

    await page.getByText("gildong@example.com").click();

    await expect(page.getByText("이메일")).toBeVisible();
    await expect(page.getByText("가입일")).toBeVisible();
    await expect(page.getByRole("button", {name: "닫기"})).toBeVisible();

    await page.getByRole("button", {name: "닫기"}).click();
    await expect(page.getByRole("button", {name: "닫기"})).toBeHidden();
});

test("사용자가 없으면 빈 상태를 보여 준다", async ({page}) => {
    await stubUserApi(page, []);

    await page.goto("/");

    await expect(page.getByText("등록된 사용자가 없습니다.")).toBeVisible();
});

test("목록을 못 불러오면 에러를 알리고, 다시 시도하면 목록이 뜬다", async ({page}) => {
    await stubUserApi(page, [GILDONG]);
    await stubUserListFailure(page);   // 나중에 등록한 쪽이 먼저 잡힌다

    page.once("dialog", (dialog) => {
        expect(dialog.message()).toContain("사용자 목록을 불러오지 못했습니다");
        return dialog.dismiss();
    });
    await page.goto("/");

    await expect(page.getByText("사용자 목록을 불러오지 못했습니다.")).toBeVisible();

    // 실패 route 를 걷어내면 원래의 성공 route 가 다시 잡힌다.
    await page.unroute("**/api/v1/users");
    await page.getByRole("button", {name: "다시 시도"}).click();

    await expect(page.getByText("홍길동")).toBeVisible();
});

test("기기가 어두운 모드면 화면도 어둡게 그린다", async ({browser}) => {
    const context = await browser.newContext({colorScheme: "dark"});
    const page = await context.newPage();
    await stubUserApi(page, [GILDONG]);

    await page.goto("/");
    await expect(page.getByText("홍길동")).toBeVisible();

    const backgrounds: string[] = await collectBackgroundColors(page);

    // theme.ts 의 어두운 모드 토큰 — bg(#0f172a) · bgElevated(#1e293b)
    expect(backgrounds).toContain("rgb(15, 23, 42)");
    expect(backgrounds).toContain("rgb(30, 41, 59)");
    // 밝은 모드 토큰이 하나라도 남아 있으면 어딘가 색을 하드코딩한 것이다.
    expect(backgrounds).not.toContain("rgb(255, 255, 255)");
    expect(backgrounds).not.toContain("rgb(248, 250, 252)");

    await context.close();
});

test("기기가 밝은 모드면 화면도 밝게 그린다", async ({browser}) => {
    const context = await browser.newContext({colorScheme: "light"});
    const page = await context.newPage();
    await stubUserApi(page, [GILDONG]);

    await page.goto("/");
    await expect(page.getByText("홍길동")).toBeVisible();

    const backgrounds: string[] = await collectBackgroundColors(page);

    expect(backgrounds).toContain("rgb(255, 255, 255)");
    expect(backgrounds).not.toContain("rgb(15, 23, 42)");

    await context.close();
});

/** 화면에 실제로 칠해진 배경색을 모은다 — 토큰이 렌더까지 도달했는지는 계산된 스타일로만 확인된다. */
async function collectBackgroundColors(page: Page): Promise<string[]> {
    return page.evaluate(() => {
        const colors = [...document.querySelectorAll("div")].map((node) => getComputedStyle(node).backgroundColor);
        return [...new Set(colors)];
    });
}
