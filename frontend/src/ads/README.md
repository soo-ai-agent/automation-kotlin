# ads — AdMob 광고 (선택 모듈)

광고로 수익을 내는 앱을 위한 자기완결 모듈이다. 배너(상시 노출)와 전면(화면 전환 지점) 둘을 담고 있고,
이 폴더 밖에서 광고를 아는 곳은 아래 "연결 지점" 4곳뿐이다.

**광고를 안 쓸 앱이면 아래 "통째로 지우기"부터 하는 편이 낫다** — 광고 SDK 가 들어 있으면
스토어 심사에서 개인정보·추적 고지가 따라온다(자세한 것은 [docs/ads.md](../../../docs/ads.md)).

## 쓰려면

1. [AdMob 콘솔](https://admob.google.com)에서 앱을 만들고 **앱 ID**(`ca-app-pub-…~…`)와
   **광고 단위 ID**(`ca-app-pub-…/…`)를 발급받는다.

2. `app.json` 을 채운다. 플러그인의 앱 ID는 지금 **구글 공개 테스트 값**이라 반드시 바꿔야 한다.

   ```json
   ["react-native-google-mobile-ads", {"androidAppId": "내-안드로이드-앱-ID", "iosAppId": "내-iOS-앱-ID"}]
   ```

   ```json
   "extra": {"admobBannerId": "내-배너-단위-ID", "admobInterstitialId": "내-전면-단위-ID"}
   ```

3. 네이티브 코드가 필요하므로 **Expo Go 로는 실제 광고가 뜨지 않는다.** dev client 를 만들어 확인한다.

   ```bash
   npx expo prebuild && npx expo run:android   # 또는 run:ios
   ```

단위 ID 를 비워 두면 개발 빌드에서는 구글 테스트 광고가, 배포 빌드에서는 아무것도 뜨지 않는다
(테스트 광고가 사용자에게 나가는 사고를 막는 기본값이다 — `lib/adUnit.ts`).

## 쓰는 법

```tsx
import {AdBanner} from "../../ads/components/AdBanner";

<AdBanner />                       // 화면 아래에 두면 앵커 배너가 붙는다
```

```ts
import {preloadInterstitial, showInterstitial} from "../../ads/lib/interstitial";

preloadInterstitial();             // 미리 받아 둔다(안 받아 두면 보여 달라는 순간에 없다)
showInterstitial();                // 준비됐을 때만 뜨고, 아니면 조용히 지나간다
```

## 알아 둘 것 네 가지

이 네 가지 때문에 "광고가 안 나온다"가 생긴다.

1. **초기화하지 않으면 영영 비어 있다.** `initializeAds()` 를 앱 시작 시 한 번 부른다(App.tsx 가 이미 부른다).

2. **Expo Go·웹 빌드에는 네이티브 모듈이 없다.** 이때 `getAdMob()` 은 없음을 돌려주고, 배너는
   개발 중에만 자리 표시 문구를 그린다. 실제 광고는 dev client·빌드에서만 보인다.

3. **배포 빌드에서 단위 ID 가 비면 지면을 그리지 않는다.** 테스트 광고가 사용자에게 나가지 않게 하려는 것이다.

4. **광고 실패는 조용히 삼킨다.** 광고는 앱 기능이 아니므로 사용자 흐름을 막거나 알림을 띄우지 않는다.

## 통째로 지우기

광고를 안 쓰는 앱이면 다섯 단계로 흔적이 사라진다.

1. `src/ads/` 폴더 삭제.

2. `App.tsx` 의 `initializeAds` import 와 `useEffect(initializeAds, [])` 한 줄 삭제.

3. `src/user/screens/User.tsx` 의 `AdBanner` import 와 `<AdBanner />` 삭제 (예시 배치).

4. `src/common/lib/config.ts` 의 `ADMOB_BANNER_ID`·`ADMOB_INTERSTITIAL_ID` 두 줄 삭제.

5. `package.json` 의 `react-native-google-mobile-ads`, `app.json` 의 플러그인 항목과
   `extra` 의 `admob*` 키 삭제 후 `npm install`.

지운 뒤 `npm run build` 가 통과하면 끝이다.

## 담지 않은 것

- **네이티브 고급형(Native Advanced) 광고** — 카드형 지면이 필요할 때 추가한다. 배너·전면과 달리
  레이아웃을 직접 그려야 해서 화면 설계에 붙는다.

- **노출 집계** — 지면이 실제로 보인 횟수를 서버로 보내고 싶으면 `AdBanner` 의 `onAdLoaded` 와
  `showInterstitial` 에서 `api/` 요청 함수를 부른다. 백엔드에 그 엔드포인트를 먼저 만들어야 한다.
