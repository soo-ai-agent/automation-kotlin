import Constants, {ExecutionEnvironment} from "expo-constants";
import type {AdMobModule} from "../types/admob";

// 광고 SDK 를 못 쓰는 실행(Expo Go)에서는 없음 — 그 자리에는 지면을 그리지 않는다.
let cached: AdMobModule | undefined;
let loaded: boolean = false;
let initialized: boolean = false;

/** Expo Go 에는 광고 네이티브 모듈이 없다 — 실제 광고는 dev client 나 빌드된 앱에서만 뜬다. */
function isExpoGo(): boolean {
    return Constants.executionEnvironment === ExecutionEnvironment.StoreClient;
}

export function getAdMob(): AdMobModule | undefined {
    if (loaded) {
        return cached;
    }
    loaded = true;
    if (isExpoGo()) {
        return cached;
    }
    try {
        cached = require("react-native-google-mobile-ads") as AdMobModule;
    } catch {
        cached = undefined;
    }
    return cached;
}

/**
 * SDK 초기화 — 초기화 전에는 광고가 내려오지 않아 지면이 영영 비어 있게 된다.
 * 앱 시작 시 한 번만 부르고, 실패는 삼킨다 — 광고는 앱 기능이 아니라 사용자 흐름을 막지 않는다.
 */
export function initializeAds(): void {
    if (initialized) {
        return;
    }
    initialized = true;
    const admob: AdMobModule | undefined = getAdMob();
    if (!admob) {
        return;
    }
    void admob.default().initialize().catch(() => {});
}
