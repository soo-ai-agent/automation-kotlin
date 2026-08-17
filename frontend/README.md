# frontend

Expo(React Native) + TypeScript 앱. 받자마자 실행되고, **iOS·Android·웹**을 한 코드로 낸다.

```bash
npm install
npm start        # Expo dev 서버 — 폰의 Expo Go 로 QR 을 찍으면 네이티브로 뜬다
npm run web      # 같은 앱을 브라우저(http://localhost:8081)로 띄운다
npm run build    # 타입 검사 + 웹 번들(dist/) — 이게 통과해야 한다
```

## 설정

주소·키는 전부 `app.json` 의 `extra` 에 있다 (`src/common/lib/config.ts` 가 읽는 유일한 창구).

| 키 | 뜻 | 기본값 |
|---|---|---|
| `apiBaseUrl` | 네이티브 **프로덕션 빌드**가 부를 백엔드 주소 | `http://localhost:8080` |
| `kakaoJsKey` | 지도 모듈용 Kakao JS 키 — 지도를 안 쓰면 비워 둔다 | `""` |
| `kakaoWebBaseUrl` | 지도 WebView 문서의 출처(카카오 콘솔 등록 도메인) | `http://localhost` |

dev 에서는 `apiBaseUrl` 을 쓰지 않는다 — 폰이 번들을 받아온 개발 머신 주소(hostUri)에서 API 주소를
파생하고, 웹 빌드는 same-origin(nginx 프록시)을 쓴다. 이유는 `config.ts` 주석에 있다.

`src/common/lib/apiClient.ts` 의 `ApiResponseDTO` 는 백엔드 `ApiResponse<T>`(`core:core-common` 의 `response/ApiResponse.kt`) 와 이미 맞춰져 있다 — `{result, data, error}`.

응답 래퍼를 바꿨다면 고치는 곳은 이 타입 하나다.

알림은 `src/common/lib/notify.ts` 하나를 거친다. 네이티브는 `Alert`, 웹 빌드는 `window.alert/confirm` 으로 갈리고, 알림 UI 를 도입하면 이 파일만 바꾼다.

## 스플래시와 앱 버전 표기

앱을 켜면 스플래시(`src/splash/` 도메인)가 잠깐 뜨고, 하단에 "앱 v1.0.0 · 서버 v0.0.1" 한 줄을 보여 준다.

앱 버전은 `app.json` 의 `version`(빌드 내장)이고, 서버 버전은 `GET /api/v1/app-info` 를 1회 조회한다.

백엔드가 이 엔드포인트를 아직 만들지 않았어도 된다 — 실패하면 서버 조각만 조용히 생략된다(스플래시는 관문이 아니다). 만들 때의 응답 모양은 `src/splash/types/appInfo.ts` 가 기준이다.

## 지도 (선택 모듈)

카카오 지도 화면이 `src/map/` 에 들어 있다. 쓰는 법과 **지도를 안 쓰는 앱에서 통째로 들어내는 절차**는 [src/map/README.md](src/map/README.md) 에 있다.

## E2E 테스트 (처음 한 번)

`e2e` 노드가 사용자 흐름 테스트를 `frontend/e2e/` 에 쓴다. 웹 빌드(react-native-web)를 브라우저로 띄워 검증하므로 Playwright 를 한 번만 설치해 두면 된다.

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

`src/user/screens/User.tsx` 의 사용자 목록 화면이 본보기다. 목록·선택·삭제·상세 모달이 다 들어 있고, 규칙대로 짜여 있다.

새 화면은 `src/user/` 안의 파일들을 복사해 도메인 이름만 바꾸는 것으로 시작한다. 순서는 types → api → services → hooks → components → screen.

스타일은 컴포넌트와 같은 폴더의 `이름.styles.ts` 에 두고, 색·간격은 `src/common/lib/theme.ts` 토큰만 쓴다.

`src/common/` 아래(`lib/`·`utils/`·`services/ServiceError`)는 여러 도메인이 쓰는 공통 코드라 그대로 둔다. 규칙 전문은 `.claude/skills/frontend-react/` 에 있다.
