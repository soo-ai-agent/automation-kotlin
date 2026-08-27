# frontend

Expo(React Native) + TypeScript 앱. 받자마자 실행되고, **iOS·Android·웹**을 한 코드로 낸다.

```bash
npm install
npm start        # Expo dev 서버 — 폰의 Expo Go 로 QR 을 찍으면 네이티브로 뜬다
npm run web      # 같은 앱을 브라우저(http://localhost:8081)로 띄운다
npm run build    # 타입 검사 + 웹 번들(dist/) — 이게 통과해야 한다
```

## 설정

주소·키는 전부 `app.json` 의 `extra` 에 있다 (`src/utils/config.ts` 가 읽는 유일한 창구).

| 키 | 뜻 | 기본값 |
|---|---|---|
| `apiBaseUrl` | 네이티브 **프로덕션 빌드**가 부를 백엔드 주소 | `http://localhost:8080` |
| `kakaoJsKey` | 지도 모듈용 Kakao JS 키 — 지도를 안 쓰면 비워 둔다 | `""` |
| `kakaoWebBaseUrl` | 지도 WebView 문서의 출처(카카오 콘솔 등록 도메인) | `http://localhost` |

dev 에서는 `apiBaseUrl` 을 쓰지 않는다 — 폰이 번들을 받아온 개발 머신 주소(hostUri)에서 API 주소를
파생하고, 웹 빌드는 same-origin(nginx 프록시)을 쓴다. 이유는 `config.ts` 주석에 있다.

`src/api/client.ts` 의 `ApiResponseDTO` 는 백엔드 `ApiResponse<T>`(`core:core-common` 의 `response/ApiResponse.kt`) 와 이미 맞춰져 있다 — `{result, data, error}`.

응답 래퍼를 바꿨다면 고치는 곳은 이 타입 하나다.

알림은 `src/utils/notify.ts` 하나를 거친다. 알림 UI 를 바꾸면 이 파일만 고치고 호출부는 손대지 않는다.

확인(`notify.confirm`)은 OS 대화상자가 아니라 **앱 디자인 팝업**(`common/components/modal/ConfirmModal.tsx`)으로 뜨고 `Promise<boolean>` 을 돌려준다. 그리는 곳은 App 루트에 하나 있는 `ConfirmDialogHost` 라, 화면마다 열림 상태를 만들 필요가 없고 서비스에서도 물어볼 수 있다. 단순 알림(success·warning·error)은 아직 OS 대화상자다.

## 스플래시와 앱 버전 표기

앱을 켜면 스플래시(`src/components/splash-screen.tsx`)가 잠깐 뜨고, 하단에 "앱 v1.0.0 · 서버 v0.0.1" 한 줄을 보여 준다.

걷히는 시점은 `src/hooks/use-splash-gate.ts` 가 정한다 — **에셋 준비(`src/utils/splash-assets.ts`)와 최소 노출 시간(1.2초)을 둘 다** 기다린다.
시간만 재면 느린 기기에서 준비도 안 된 화면이 열리고, 준비만 재면 빠른 기기에서 로고가 스치고 만다.

이미지를 추가하면 `splash-assets.ts` 의 `PRELOAD_IMAGES` 에 넣는다. 그러면 스플래시가 그만큼 더 기다렸다가 걷히고, 첫 화면이 깜빡이지 않는다.

네이티브 스플래시(앱 아이콘 화면)는 `expo-splash-screen` 이 잡고 있다가 우리 스플래시가 실제로 그려진 뒤 내려간다 — 그래야 둘 사이에 흰 화면이 스치지 않는다.

앱 버전은 `app.json` 의 `version`(빌드 내장)이고, 서버 버전은 `GET /api/v1/app-info` 를 1회 조회한다.

백엔드가 이 엔드포인트를 아직 만들지 않았어도 된다 — 실패하면 서버 조각만 조용히 생략된다(스플래시는 관문이 아니다). 만들 때의 응답 모양은 `src/api/app-info.ts` 의 `AppInfo` 가 기준이다.

## 지도 (선택 모듈)

카카오 지도 화면이 `/map` 라우트에 들어 있다. 쓰는 법과 **지도를 안 쓰는 앱에서 들어내는 절차**는 [docs/map.md](docs/map.md) 에 있다.

## 광고 (선택 모듈)

AdMob 배너·전면 광고가 `src/components/ad-banner.tsx` 와 `src/utils/admob*` 에 들어 있다. 단위 ID 가 비어 있어 **배포 빌드에서는 아무것도 뜨지 않는 상태**이고, 개발 빌드에서만 구글 테스트 광고가 보인다.

쓰는 법과 **광고를 안 쓰는 앱에서 들어내는 절차**는 [docs/ads.md](docs/ads.md) 에, 넣을지 말지 판단과 스토어 준비물은 [../docs/ads.md](../docs/ads.md) 에 있다.

광고 SDK 는 네이티브 전용이라 웹 빌드에서는 자동으로 빠진다(`lib/admob.web.ts`).

## E2E 테스트

사용자 흐름 테스트가 `frontend/e2e/` 에 있다. 웹 빌드(react-native-web)를 브라우저로 띄워 사람이 하듯 클릭해 검증한다.

`playwright.config.ts` 와 `npm run e2e` 스크립트는 이미 들어 있다. 브라우저 실행 파일만 각자 한 번 내려받으면 된다.

```bash
npx playwright install chromium
npm run e2e
```

## 린트

```bash
npm run lint       # Expo 공식 규칙 + 포맷 검사
npm run lint:fix   # 고칠 수 있는 것은 고친다
```

포맷(들여쓰기·따옴표·줄 길이)은 도구가 정한다. 다만 **객체 줄바꿈은 일부러 규칙을 두지 않았다** — `frontend-common` 의 "채워 적기"를 도구가 깨지 않게 하려는 것이다.

돌리면 `npm run web`(Metro 개발 서버)이 자동으로 뜨고 끝나면 내려간다. 백엔드는 필요 없다 — API 응답은 `e2e/fixtures.ts` 가 가로채 가짜로 준다.

| 파일 | 담는 흐름 |
|---|---|
| `e2e/user.spec.ts` | 목록·삭제·삭제 취소·선택 삭제·상세 모달·빈 상태·에러와 재시도 (8개) |
| `e2e/map.spec.ts` | 지도로 갔다 돌아오기, 지도 주소로 바로 들어온 경우 (2개) |
| `e2e/fixtures.ts` | 가짜 응답 — 삭제하면 다음 조회에서 빠지도록 상태를 가진다 |

작성 규칙은 `.claude/skills/frontend-e2e/SKILL.md` 에 있다.

## 밝은 모드·어두운 모드

기기 설정을 따른다 (`app.json` 의 `userInterfaceStyle: "automatic"`).

색은 `src/theme.ts` 에 밝게/어둡게 **두 벌**이 짝으로 있고, 컴포넌트는 `useStyles(createStyles)` 로 지금 모드의 색을 받는다.

```tsx
const styles = useStyles(createStyles);
// …
const createStyles = (colors: Colors) => StyleSheet.create({
    box: {backgroundColor: colors.bg, color: colors.text},
});
```

`StyleSheet.create` 를 모듈 최상위에 두면 모듈이 읽힐 때 한 번만 돌아 모드가 바뀌어도 그대로다 — 그래서 생성을 함수로 미룬다.
`useStyles` 가 (함수 × 모드)마다 한 번만 만들어 재사용하므로 목록의 행이 100개여도 생성은 한 번이다.

새 색이 필요하면 `theme.ts` 의 `palette.light` 와 `palette.dark` **양쪽에** 넣는다. 타입(`ColorPalette`)이 한쪽만 넣는 것을 막는다.

## 스토어 배포

App Store·Play Store 에 올릴 설정과 자리 표시 에셋이 들어 있다 — `app.json` 의 식별자·아이콘·스플래시, `eas.json` 의 빌드 프로필 셋.

**지금 값 그대로는 올릴 수 없다.** 앱 식별자가 `com.example.frontend` 이고 아이콘이 자동 생성한 도형이며 AdMob 은 구글 테스트 ID 다.

바꿔야 할 것과 계정·자격증명·심사 준비물은 [docs/release.md](docs/release.md) 에 있다.

## 백엔드와의 계약

`web` 노드는 루트 [CONTRACT.md](../CONTRACT.md) 와 `backend/` 의 실제 응답 DTO 코드를 읽고 화면을 만든다.

필드 이름은 **서버가 주는 이름 그대로** 쓴다. Kotlin + Jackson 기본 설정이라 camelCase 로 내려온다 — 프론트에서 개명하지 않는다.

## 새 화면 만들기

폴더 구조는 **역할이 최상위**다. Expo 공식 스킬 `expo-project-structure` 의 골격을 그대로 쓴다.

```
src/
├── app/                  # Expo Router 라우트 전용 — 이 안의 모든 파일이 라우트다
├── screens/<화면>/       # 화면 본체. 이 화면만 쓰는 components/ · hooks/ 를 안에 둔다
├── components/ hooks/    # 두 화면 이상이 쓰는 것만 올라온다
├── api/                  # 서버와 말하는 코드 — 자원마다 한 파일
├── utils/                # 순수 헬퍼 · 플랫폼 래퍼 · 나란한 테스트
├── constants/            # 사용자 문장 — 화면·기능마다 한 파일
└── theme.ts              # 색·간격·타이포 토큰
```

새 화면은 아래에서 위로 만든다 — api → constants → hooks → components → screen → route.

파일 이름은 전부 kebab-case 이고, 스타일은 `StyleSheet.create` 를 컴포넌트 파일 맨 아래에 두고 색·간격은 `src/theme.ts` 토큰만 쓴다.

`src/screens/user/` 가 본보기다. 목록·선택·삭제·상세 모달이 다 들어 있고, 규칙대로 짜여 있다.

규칙은 두 층이다 — 프레임워크 사용법은 `.claude/skills/expo/` 에 [expo/skills](https://github.com/expo/skills) 를 벤더링해 두었고,
저장소 고유 규칙은 `.claude/skills/frontend-*` 7종에 있다. 색인은 `.claude/skills/README.md`.
