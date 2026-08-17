import Constants from "expo-constants";
import {Platform} from "react-native";
import appConfig from "../../../app.json";

const {extra} = appConfig.expo;

/** 백엔드 기본 포트 — Spring Boot 기본값. 바꿨다면 여기와 app.json extra.apiBaseUrl 을 함께 고친다. */
const BACKEND_PORT: number = 8080;

/**
 * 웹 빌드는 빈 문자열(same-origin) — nginx 가 /api/ 를 백엔드로 프록시한다(frontend/nginx.conf).
 *
 * 네이티브 dev(Expo Go·dev client)는 번들을 내려준 개발 머신 주소(hostUri)에서 API 주소를 파생한다.
 * localhost 는 폰에서 폰 자신을 가리켜 쓸 수 없고, LAN IP 하드코딩은 공유기가 바뀔 때마다
 * 조용히 전량 실패한다. 폰이 번들을 받아온 주소는 항상 지금 통하는 개발 머신 주소다.
 *
 * 네이티브 프로덕션 빌드는 hostUri 가 없으므로 app.json extra.apiBaseUrl 을 쓴다.
 */
function resolveApiBaseUrl(): string {
    if (Platform.OS === "web") {
        return "";
    }
    const hostUri: string | undefined = Constants.expoConfig?.hostUri;   // 프로덕션 빌드에는 없음
    if (hostUri) {
        const host: string = hostUri.split(":")[0];
        return `http://${host}:${BACKEND_PORT}`;
    }
    return extra.apiBaseUrl;
}

export const API_BASE_URL = resolveApiBaseUrl();
export const KAKAO_JS_KEY = extra.kakaoJsKey;
/** 지도 WebView 문서의 출처 — Kakao 콘솔의 "웹 플랫폼 도메인"에 등록된 주소여야 SDK 가 동작한다. */
export const KAKAO_WEB_BASE_URL = extra.kakaoWebBaseUrl;
/** 광고 단위 ID — 비우면 개발 빌드에서만 테스트 광고가 뜬다 (src/ads/README.md). */
export const ADMOB_BANNER_ID = extra.admobBannerId;
export const ADMOB_INTERSTITIAL_ID = extra.admobInterstitialId;
