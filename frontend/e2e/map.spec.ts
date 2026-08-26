import {expect, test} from "@playwright/test";

/**
 * 지도 화면 진입·복귀 흐름. 웹 빌드에서는 지도 대신 네이티브 안내 문구가 뜬다(KakaoMapView.web.tsx).
 */

test("사용자 화면에서 지도로 갔다가 뒤로 돌아온다", async ({page}) => {
    await page.route("**/api/v1/users", (route) => route.fulfill({json: {result: "SUCCESS", data: [], error: null}}));

    await page.goto("/");
    await page.getByRole("button", {name: "지도", exact: true}).click();

    await expect(page.getByText("지도는 네이티브 앱(iOS·Android)에서 표시됩니다.")).toBeVisible();

    await page.getByRole("button", {name: "← 뒤로"}).click();
    await expect(page.getByText("사용자", {exact: true})).toBeVisible();
});
