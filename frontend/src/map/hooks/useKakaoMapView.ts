import {useCallback, useEffect, useMemo, useRef} from "react";
import type {RefObject} from "react";
import {WebView, type WebViewMessageEvent} from "react-native-webview";
import {MapResultMessages, MapWebViewMessageType} from "../enums/map";
import {KAKAO_JS_KEY} from "../../common/lib/config";
import {buildKakaoMapHtml} from "../lib/kakaoMapHtml";
import {notify} from "../../common/lib/notify";
import type {LatLng, MapMarker} from "../types/map";

export type KakaoMapViewParams = {
    center: LatLng;
    level: number;
    markers: MapMarker[];
};

export type KakaoMapViewState = {
    webViewRef: RefObject<WebView | null>;
    html: string;
    payload: string;
    handleWebViewMessage: (event: WebViewMessageEvent) => void;
};

// 화면을 오갈 때마다 같은 알림이 반복되지 않게 세션당 1회만 알린다 — 지도 없이도 나머지 화면은 계속 쓸 수 있다.
let mapLoadFailureNotified = false;

export function useKakaoMapView({center, level, markers}: KakaoMapViewParams): KakaoMapViewState {
    const webViewRef = useRef<WebView | null>(null);

    const html: string = useMemo(() => buildKakaoMapHtml(KAKAO_JS_KEY), []);

    const payload: string = useMemo(
        () => JSON.stringify({center, level, markers}),
        [center, level, markers],
    );

    useEffect(() => {
        webViewRef.current?.injectJavaScript(`window.__update && window.__update(${payload}); true;`);
    }, [payload]);

    const handleWebViewMessage = useCallback((event: WebViewMessageEvent) => {
        if (!isMapLoadFailedMessage(event.nativeEvent.data)) {
            return;
        }
        if (!mapLoadFailureNotified) {
            mapLoadFailureNotified = true;
            notify.error(MapResultMessages.LOAD_FAILED);
        }
    }, []);

    return {webViewRef, html, payload, handleWebViewMessage};
}

/** WebView 는 지도 밖 출처의 postMessage 도 실어 나른다 — 모양이 안 맞으면 무시한다. */
function isMapLoadFailedMessage(raw: string): boolean {
    let parsed: unknown = null;   // JSON.parse 는 임의 문자열 경계라 모양을 보장할 수 없다.
    try {
        parsed = JSON.parse(raw);
    } catch {
        return false;
    }
    if (typeof parsed !== "object" || parsed === null) {
        return false;
    }
    return (parsed as {type?: unknown}).type === MapWebViewMessageType.MAP_LOAD_FAILED;
}
