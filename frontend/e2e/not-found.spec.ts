import {expect, test} from "@playwright/test";
import {GILDONG, stubUserApi} from "./fixtures";

test("없는 주소로 들어가면 안내와 처음으로 버튼을 보여 준다", async ({page}) => {
    await stubUserApi(page, [GILDONG]);

    await page.goto("/이런-화면은-없다");

    await expect(page.getByText("없는 화면입니다.")).toBeVisible();

    await page.getByRole("link", {name: "처음으로"}).click();

    await expect(page.getByText("홍길동")).toBeVisible();
});
