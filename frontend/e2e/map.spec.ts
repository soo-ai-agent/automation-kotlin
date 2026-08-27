import {expect, test} from "@playwright/test";
import {GILDONG, stubUserApi} from "./fixtures";

test("사용자 화면에서 지도로 갔다가 돌아온다", async ({page}) => {
    await stubUserApi(page, [GILDONG]);
    await page.goto("/");
    await expect(page.getByText("홍길동")).toBeVisible();

    await page.getByRole("link", {name: "지도"}).click();

    await expect(page).toHaveURL(/\/map$/);
    // 웹 빌드는 react-native-webview 를 못 써서 자리 표시 문구가 대신 나온다(kakao-map-view.web.tsx).
    await expect(page.getByText("지도는 네이티브 앱(iOS·Android)에서 표시됩니다.")).toBeVisible();

    await page.getByRole("button", {name: "← 뒤로"}).click();

    await expect(page).toHaveURL(/localhost:8081\/$/);
    await expect(page.getByText("홍길동")).toBeVisible();
    // 되돌아가기는 pop 이라 사용자 화면이 두 벌 쌓이지 않는다 — push 로 돌아가면 여기서 2가 된다.
    await expect(page.getByText("홍길동")).toHaveCount(1);
    await expect(page.getByText("지도는 네이티브 앱(iOS·Android)에서 표시됩니다.")).toHaveCount(0);
});

test("지도를 주소로 바로 열어도 뒤로 버튼이 사용자 화면으로 보낸다", async ({page}) => {
    await stubUserApi(page, [GILDONG]);

    // 되돌아갈 자리가 없는 진입 — router.back() 만으로는 버튼이 먹통이 된다.
    await page.goto("/map");
    await expect(page.getByText("지도는 네이티브 앱(iOS·Android)에서 표시됩니다.")).toBeVisible();

    await page.getByRole("button", {name: "← 뒤로"}).click();

    await expect(page.getByText("홍길동")).toBeVisible();
});
