# map — 카카오 지도 화면 (선택 모듈)

지도를 쓰는 앱을 위한 자기완결 모듈이다. WebView 에 카카오 지도 SDK 를 띄우고, RN 은
`중심·배율·마커` payload 하나로만 지도와 이야기한다. 이 폴더 밖에서 지도를 아는 곳은 아래 "연결 지점" 3곳뿐이다.

## 쓰려면

1. [Kakao Developers](https://developers.kakao.com) 앱의 **JavaScript 키**를 `app.json` `extra.kakaoJsKey` 에 넣는다.

2. 카카오 콘솔 "웹 플랫폼 도메인"에 `extra.kakaoWebBaseUrl`(기본 `http://localhost`)을 등록한다. WebView 문서의 출처가 이 주소다.

키가 없으면 지도 자리에 설정 안내가 뜨고, SDK 로드가 실패하면 `notify` 로 한 번 알린 뒤 나머지 화면은 그대로 동작한다.

웹 빌드(`expo export --platform web`)에서는 react-native-webview 가 동작하지 않아 자리 표시 문구가 대신 나온다
(`KakaoMapView.web.tsx` — Metro 가 웹 번들에서 자동 선택).

## 지도를 안 쓰는 앱이면 통째로 지운다

1. `src/map/` 폴더 삭제.

2. `App.tsx` 의 `MapScreen` import 와 `<Stack.Screen name="Map" …>` 한 줄 삭제.

3. `src/common/types/navigation.ts` 의 `Map` 항목 삭제.

4. `src/user/screens/User.tsx` 의 "지도" 버튼 삭제 (예시 진입점).

5. `package.json` 의 `react-native-webview`, `app.json` `extra` 의 `kakaoJsKey`·`kakaoWebBaseUrl` 삭제.

지운 뒤 `npm run build` 가 통과하면 끝이다.
