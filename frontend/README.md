# frontend

React + TypeScript 앱. 받자마자 실행된다.

```bash
npm install
npm run dev      # 개발 서버
npm run build    # 타입 검사 + 빌드 — 이게 통과해야 한다
```

## 설정

주소·경로는 `frontend/.env` 에 있다. 처음 한 번 `cp .env.example .env` 하고 값을 채운다. 백엔드 기본 포트는 Spring Boot 기본값인 8080 이다.

`src/common/lib/apiClient.ts` 의 `ApiResponseDTO` 는 백엔드 `ApiResponse<T>`(`core:core-common` 의 `response/ApiResponse.kt`) 와 이미 맞춰져 있다 — `{result, data, error}`.

응답 래퍼를 바꿨다면 고치는 곳은 이 타입 하나다.

알림은 `src/common/lib/notify.ts` 하나를 거친다. 지금은 `window.alert` 이고, 알림 UI 를 도입하면 이 파일만 바꾼다.

## E2E 테스트 (처음 한 번)

`e2e` 노드가 사용자 흐름 테스트를 `frontend/e2e/` 에 쓴다. Playwright 를 한 번만 설치해 두면 된다.

```bash
npm install -D @playwright/test
npx playwright install chromium
```

`package.json` 의 `scripts` 에 `"e2e": "playwright test"` 를 넣고, `playwright.config.ts` 를 만든다. 설정 내용과 작성 규칙은 `.claude/skills/frontend-e2e/SKILL.md` 에 있다.

```bash
npm run e2e
```

## 백엔드와의 계약

`web` 노드는 루트 [CONTRACT.md](../CONTRACT.md) 와 `backend/` 의 실제 응답 DTO 코드를 읽고 화면을 만든다.

필드 이름은 **서버가 주는 이름 그대로** 쓴다. Kotlin + Jackson 기본 설정이라 camelCase 로 내려온다 — 프론트에서 개명하지 않는다.

## 새 화면 만들기

`src/user/pages/User.tsx` 의 사용자 목록 화면이 본보기다. 목록·선택·삭제·상세 모달이 다 들어 있고, 규칙대로 짜여 있다.

새 화면은 `src/user/` 안의 13개 파일을 복사해 도메인 이름만 바꾸는 것으로 시작한다. 순서는 types → api → services → hooks → components → page.

`src/common/` 아래(`lib/`·`utils/`·`services/ServiceError`)는 여러 도메인이 쓰는 공통 코드라 그대로 둔다. 규칙 전문은 `.claude/skills/frontend-react/` 에 있다.
