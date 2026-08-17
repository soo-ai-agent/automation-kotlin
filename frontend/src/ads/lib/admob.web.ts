import type {AdMobModule} from "../types/admob";

/**
 * 웹 빌드용 대체 구현 — 광고 SDK 는 네이티브 전용이다.
 *
 * 단순히 실행 시점에 건너뛰는 것으로는 부족하다: Metro 는 `require` 를 정적으로 해석해
 * try/catch 안이라도 웹 번들에 넣는데, 그 패키지가 RN 내부 모듈을 불러 웹 번들이 깨진다.
 * 그래서 웹에서는 이 파일이 대신 잡히도록 파일째 분리한다(호출부는 구분을 모른다).
 */
export function getAdMob(): AdMobModule | undefined {
    return undefined;
}

export function initializeAds(): void {
    return;
}
