/**
 * 광고 SDK 모듈의 타입. 타입 자리에서만 쓰므로 웹 번들에는 들어가지 않는다
 * (실제 import 는 네이티브 전용 `lib/admob.ts` 에만 있다).
 */
export type AdMobModule = typeof import("react-native-google-mobile-ads");
