# 카카오 지도 화면 (선택 기능)

> **이 문서는 사람이 읽습니다.** 지도를 쓸지 말지와 들어내는 절차를 담습니다.

지도를 쓰는 앱을 위한 예시 화면이다. WebView 에 카카오 지도 SDK 를 띄우고, RN 은
`중심·배율·마커` payload 하나로만 지도와 이야기한다.

## 파일

역할이 최상위 폴더인 구조라 지도 코드도 역할별로 나뉘어 있다. 지도를 이루는 파일은 이 여섯이다.

| 파일 | 하는 일 |
|---|---|
| `src/app/map.tsx` | `/map` 라우트 — 화면 하나를 그린다 |
| `src/screens/map/index.tsx` | 지도 화면 본체 |
| `src/components/kakao-map-view.tsx` | 네이티브 구현(WebView) |
| `src/components/kakao-map-view.web.tsx` | 웹 대체 구현(자리 표시) |
| `src/components/kakao-map-view.types.ts` | 두 구현이 공유하는 props·좌표 타입 |
| `src/hooks/use-kakao-map-view.ts` | WebView 참조·payload·메시지 처리 |
| `src/utils/kakao-map-html.ts` | WebView 문서와 그 경계 계약 |

## 쓰려면

1. [Kakao Developers](https://developers.kakao.com) 앱의 **JavaScript 키**를 `app.json` `extra.kakaoJsKey` 에 넣는다.

2. 카카오 콘솔 "웹 플랫폼 도메인"에 `extra.kakaoWebBaseUrl`(기본 `http://localhost`)을 등록한다. WebView 문서의 출처가 이 주소다.

키가 없으면 지도 자리에 설정 안내가 뜨고, SDK 로드가 실패하면 `notify` 로 한 번 알린 뒤 나머지 화면은 그대로 동작한다.

웹 빌드(`expo export --platform web`)에서는 react-native-webview 가 동작하지 않아 자리 표시 문구가 대신 나온다
(`kakao-map-view.web.tsx` — Metro 가 웹 번들에서 자동 선택).

## 지도를 안 쓰는 앱이면 지운다

1. 위 표의 파일 일곱 개를 지운다.

2. `src/screens/user/index.tsx` 의 "지도" 버튼(`<Link href="/map" …>` 블록)을 지운다 (예시 진입점).

3. `src/constants/map.ts` 를 지우고 `src/constants/index.ts` 의 재노출 한 줄을 지운다.

4. `src/utils/config.ts` 의 `KAKAO_JS_KEY`·`KAKAO_WEB_BASE_URL` 두 줄을 지운다.

5. `package.json` 의 `react-native-webview`, `app.json` `extra` 의 `kakaoJsKey`·`kakaoWebBaseUrl` 을 지운다.

**`src/app/map.tsx` 를 반드시 지운다** — 라우트 파일이 남으면 `/map` 이 계속 살아 있다.

지운 뒤 `npm run build` 가 통과하면 끝이다.
