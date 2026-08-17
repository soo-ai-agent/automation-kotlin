import {useState} from "react";
import {Text, View} from "react-native";
import {ADMOB_BANNER_ID} from "../../common/lib/config";
import {getAdMob} from "../lib/admob";
import type {AdMobModule} from "../types/admob";
import {resolveAdUnitId} from "../lib/adUnit";
import {AdsMessages} from "../enums/ads";
import {styles} from "./AdBanner.styles";

/**
 * 앵커 배너(적응형) — 화면 아래에 상시 붙는 좁은 띠에 쓴다.
 * 광고가 들어오기 전이나 SDK 가 없는 실행에서는 자리를 잡지 않는다(빈 띠가 레이아웃을 밀지 않게).
 */
export function AdBanner() {
    const admob: AdMobModule | undefined = getAdMob();
    // 광고가 실제로 들어왔는지는 SDK 콜백으로만 알 수 있고 밖으로 나가지 않는다 — 자기 표현 상태(1-1장).
    const [loaded, setLoaded] = useState(false);

    if (!admob) {
        // 웹 빌드·Expo Go 에는 광고 모듈이 없다. 개발 중에는 자리라도 보여 레이아웃을 확인할 수 있게 하고
        // (실광고로 오해하지 않게 문구를 적는다), 배포 빌드에서는 아무것도 그리지 않는다.
        if (!__DEV__) {
            return null;
        }
        return (
            <View style={[styles.wrap, styles.placeholder]}>
                <Text style={styles.placeholderText}>{AdsMessages.DEV_PLACEHOLDER}</Text>
            </View>
        );
    }

    const adUnitId: string = resolveAdUnitId(ADMOB_BANNER_ID, admob.TestIds.BANNER);
    if (!adUnitId) {
        return null;
    }

    const {BannerAd, BannerAdSize} = admob;
    return (
        <View style={loaded ? styles.wrap : undefined}>
            <BannerAd
                unitId={adUnitId}
                size={BannerAdSize.ANCHORED_ADAPTIVE_BANNER}
                requestOptions={{requestNonPersonalizedAdsOnly: true}}
                onAdLoaded={() => setLoaded(true)}
                onAdFailedToLoad={() => setLoaded(false)}
            />
        </View>
    );
}
