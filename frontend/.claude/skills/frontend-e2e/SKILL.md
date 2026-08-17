---
name: frontend-e2e
description: Playwright E2E 테스트 작성과 리뷰 규칙. frontend/e2e 의 spec 파일 자리와 이름, 선택자 정책(getByRole 우선), 임의 대기 금지, window.alert·confirm 다이얼로그 처리, 백엔드를 띄울지 목킹할지 판단을 다룬다. e2e 노드가 항상 사용하고, "E2E 추가", "사용자 흐름 테스트" 요청에도 사용할 것.
---

# E2E 테스트 (Playwright)

**자리:** `frontend/e2e/<도메인>.spec.ts`

## 무엇을 하는 테스트인가

유닛 테스트가 함수 하나를 보는 것이라면, E2E 는 **브라우저를 실제로 띄워 사람이 하는 것과 똑같이 클릭하고 입력해 본다.**

그래서 "목록이 보이고 → 삭제를 누르고 → 확인을 눌렀더니 → 목록에서 사라졌다" 같은 **화면과 서버를 잇는 흐름**을 확인한다.

한 파일에 한 도메인, 한 `test()` 에 한 흐름을 담는다. 흐름 하나가 길면 나누지 말고 그대로 둔다 — 중간을 잘라 놓으면 사용자 관점이 사라진다.

## 처음 한 번 — 설치와 설정

사람이 프론트를 세팅할 때 한 번만 한다 (`frontend/README.md` 참고). 이미 되어 있으면 넘어간다.

```bash
cd frontend
npm install -D @playwright/test
npx playwright install chromium
```

```json
// package.json 의 scripts 에 추가
"e2e": "playwright test",
"e2e:ui": "playwright test --ui"
```

```ts
// frontend/playwright.config.ts
import {defineConfig} from "@playwright/test";

export default defineConfig({
    testDir: "./e2e",
    use: {
        baseURL: "http://localhost:8081",
        trace: "on-first-retry",   // 실패했을 때만 추적 파일을 남긴다
    },
    // 테스트를 돌리면 웹 개발 서버(react-native-web)를 알아서 띄우고, 끝나면 내린다
    webServer: {
        command: "npm run web",
        url: "http://localhost:8081",
        reuseExistingServer: true,
        timeout: 120000,   // 첫 실행은 Metro 번들링 때문에 기본 60초를 넘길 수 있다
    },
});
```

`.gitignore` 에 `frontend/test-results/`, `frontend/playwright-report/` 를 넣는다.

## 이 앱은 RN 을 웹으로 띄운 것이다

앱은 Expo(React Native)이고, E2E 는 같은 코드를 react-native-web 으로 브라우저에 띄워 검증한다. 그래서 둘만 다르다.

- 요소 지정: JSX 의 `accessibilityRole`/`accessibilityLabel` 이 브라우저 role/name 으로 렌더된다 — `getByRole` 이 그대로 통한다. testid 가 필요하면 RN 의 `testID` prop 을 쓴다(웹에서 `data-testid` 로 렌더).

- 첫 화면 앞에 스플래시가 잠깐(약 1.2초) 떠 있다 — `expect` 의 자동 재시도가 알아서 넘기므로 임의 대기를 넣지 않는다.

## 백엔드를 띄울까, 가짜 응답을 줄까

**둘 다 맞다. 무엇을 확인하려는지에 따라 고른다.**

| 확인하려는 것 | 방법 |
|---|---|
| 화면 흐름·표시·분기 (대부분) | `page.route` 로 API 응답을 가로채 가짜로 준다 |
| 프론트와 백엔드가 실제로 맞물리는지 | 백엔드를 띄우고 진짜로 호출한다 |

가짜 응답을 쓰면 **백엔드 없이도 CI 에서 돌아가고, 실패했을 때 원인이 프론트라는 것이 분명해진다.** 기본으로 이쪽을 쓴다.

```ts
await page.route("**/api/v1/users", async (route) => {
    await route.fulfill({
        json: {result: "SUCCESS", data: [{id: 1, name: "홍길동", email: "a@b.c", createdAt: "2026-08-14T10:00:00", lastLoginAt: null}], error: null},
    });
});
```

**가짜 응답도 `ApiResponse` 껍데기(`{result, data, error}`)를 그대로 지켜야 한다.** 껍데기를 빼먹으면 `apiClient` 가 실패로 처리한다.

필드 이름과 타입은 지어내지 말고 `CONTRACT.md` 와 백엔드 응답 DTO 에서 확인한다.

백엔드를 실제로 띄울 수 없는 환경이면 **테스트 코드만 남기고 실행하지 못한 이유를 결과에 적는다.** 돌리지 않은 것을 통과했다고 적지 않는다.

## 확인 팝업과 알림 — 둘을 다르게 다룬다

`notify.confirm` 은 **앱 안에서 그리는 팝업**(`ConfirmModal`)이라 평범한 요소로 검증한다.

```ts
await page.getByRole("button", {name: "삭제"}).click();       // 목록의 삭제 버튼
await page.getByRole("button", {name: "삭제"}).last().click(); // 팝업의 확인 버튼
await expect(page.getByText("홍길동")).toBeHidden();
```

취소를 검증할 때도 같다 — 팝업의 "취소"를 누르고 목록이 그대로인지 본다.

**반면 `notify.success`·`warning`·`error` 는 아직 OS 대화상자(`window.alert`)다.** Playwright 는 이것을 자동으로 닫아 버리므로, 문구를 확인하려면 핸들러를 먼저 건다.

```ts
page.once("dialog", (dialog) => {
    expect(dialog.message()).toContain("삭제되었습니다");
    return dialog.dismiss();
});
```

`once` 를 쓴다. `on` 으로 걸면 다음 테스트까지 남는다. 알림까지 앱 UI(토스트 등)로 바꾸면 이 절은 필요 없어진다.

## 무엇으로 요소를 찾나

**사람이 화면을 알아보는 방식대로 찾는다.** 그래야 마크업을 바꿔도 테스트가 안 깨지고, 접근성도 함께 검증된다.

| 순위 | 방법 | 예 |
|---|---|---|
| 1 | 역할과 이름 | `page.getByRole("button", {name: "삭제"})` |
| 2 | 라벨·플레이스홀더 | `page.getByLabel("이메일")` |
| 3 | 보이는 텍스트 | `page.getByText("등록된 사용자가 없습니다")` |
| 4 | 위 셋으로 안 될 때만 | `page.getByTestId("user-row")` + JSX 에 `testID`(웹에서 `data-testid` 로 렌더) |

**CSS 클래스·태그 구조로 찾지 않는다.** `page.locator(".btn-danger > span")` 같은 선택자는 스타일만 바꿔도 깨진다.

## 기다리는 법 — 임의 대기 금지

```ts
// ❌ 느린 환경에서 깨지고, 빠른 환경에서 시간만 버린다
await page.waitForTimeout(2000);

// ✅ 조건이 만족될 때까지 알아서 기다린다
await expect(page.getByText("홍길동")).toBeVisible();
await expect(page.getByRole("row")).toHaveCount(3);
```

Playwright 의 `expect` 는 조건이 맞을 때까지 자동으로 재시도한다. `waitForTimeout` 은 **디버깅할 때만** 쓰고 커밋하지 않는다.

## 적발 신호

| 신호 | 문제 | 심각도 |
|---|---|---|
| `waitForTimeout` 으로 대기 | 환경에 따라 깨지는 불안정한 테스트 | Critical |
| `window.alert` 을 쓰는 흐름(notify.success 등)에 `page.once("dialog")` 없음 | 자동으로 닫혀 검증이 조용히 무의미해짐 | Critical |
| 가짜 응답에 `ApiResponse` 껍데기(`{result, data, error}`) 누락 | `apiClient` 가 실패로 처리 | Critical |
| 실행하지 않은 테스트를 통과했다고 보고 | 사실과 다른 보고 | Critical |
| CSS 클래스·태그 구조 선택자 | 스타일 변경만으로 깨짐 | Important |
| 필드 이름·타입을 `CONTRACT.md` 확인 없이 지어냄 | 실제 응답과 어긋난 테스트 | Important |
| 한 `test()` 에 관련 없는 흐름 여러 개 | 실패 원인 파악 어려움 | Important |
| `page.on("dialog")` 를 `once` 없이 사용 | 다음 테스트에 핸들러가 새어 나감 | Important |
| 테스트끼리 실행 순서에 의존 | 병렬 실행에서 깨짐 | Important |

## 체크리스트

- [ ] 한 `test()` 가 사용자 흐름 하나를 처음부터 끝까지 담는가

- [ ] 요소를 역할·라벨·텍스트로 찾는가 (CSS 선택자가 아닌가)

- [ ] `waitForTimeout` 없이 `expect` 의 자동 재시도로 기다리는가

- [ ] OS 대화상자(notify.success 등)를 쓰는 흐름에 `page.once("dialog", ...)` 를 걸었는가 (확인 팝업은 일반 요소로 검증)

- [ ] 가짜 응답이 `ApiResponse` 껍데기와 `CONTRACT.md` 의 필드를 지키는가

- [ ] 다른 테스트가 먼저 돌았는지에 기대지 않는가

- [ ] 실행한 것과 실행하지 못한 것을 결과에 구분해 적었는가
