import type {InterstitialAd} from "react-native-google-mobile-ads";
import {ADMOB_INTERSTITIAL_ID} from "../../common/lib/config";
import {getAdMob} from "./admob";
import type {AdMobModule} from "../types/admob";
import {resolveAdUnitId} from "./adUnit";

/**
 * 전면 광고 — 화면 전환처럼 흐름이 끊기는 지점에서만 쓴다.
 * 미리 받아 두지 않으면(preload) 보여 달라는 순간에 아직 없어서 그냥 지나간다.
 */

// SDK 나 단위 ID 가 없으면 만들지 못해 없음.
let ad: InterstitialAd | undefined;
let loaded: boolean = false;
let showing: boolean = false;

function ensureAd(): InterstitialAd | undefined {
    if (ad) {
        return ad;
    }
    const admob: AdMobModule | undefined = getAdMob();
    if (!admob) {
        return undefined;
    }
    const adUnitId: string = resolveAdUnitId(ADMOB_INTERSTITIAL_ID, admob.TestIds.INTERSTITIAL);
    if (!adUnitId) {
        return undefined;
    }
    const created: InterstitialAd = admob.InterstitialAd.createForAdRequest(adUnitId, {
        requestNonPersonalizedAdsOnly: true,
    });
    created.addAdEventListener(admob.AdEventType.LOADED, () => {
        loaded = true;
    });
    created.addAdEventListener(admob.AdEventType.CLOSED, () => {
        loaded = false;
        showing = false;
        // 다음 기회를 위해 곧바로 다시 받아 둔다.
        try {
            created.load();
        } catch {
            return;
        }
    });
    created.addAdEventListener(admob.AdEventType.ERROR, () => {
        loaded = false;
    });
    ad = created;
    return created;
}

export function preloadInterstitial(): void {
    try {
        const instance: InterstitialAd | undefined = ensureAd();
        if (instance && !loaded) {
            instance.load();
        }
    } catch {
        return;
    }
}

/** 준비된 광고가 있을 때만 보여 준다 — 없으면 조용히 지나간다(흐름을 막지 않는다). */
export function showInterstitial(): void {
    try {
        if (loaded && ad && !showing) {
            showing = true;
            ad.show();
        }
    } catch {
        showing = false;
    }
}
