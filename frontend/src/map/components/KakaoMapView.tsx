import {Text, View} from "react-native";
import {WebView} from "react-native-webview";
import {KAKAO_JS_KEY, KAKAO_WEB_BASE_URL} from "../../common/lib/config";
import {useKakaoMapView, type KakaoMapViewState} from "../hooks/useKakaoMapView";
import {styles} from "./KakaoMapView.styles";
import type {KakaoMapViewProps} from "./KakaoMapView.types";

export function KakaoMapView({center, level, markers, style}: KakaoMapViewProps) {
    const map: KakaoMapViewState = useKakaoMapView({center, level, markers});

    if (!KAKAO_JS_KEY) {
        return (
            <View style={[styles.fallback, style]}>
                <Text style={styles.fallbackText}>지도 키(kakaoJsKey)가 설정되지 않았습니다.</Text>
                <Text style={styles.fallbackHint}>
                    app.json extra.kakaoJsKey 에 Kakao JS 키를 넣어주세요.
                </Text>
            </View>
        );
    }

    return (
        <View style={[styles.container, style]}>
            <WebView
                ref={map.webViewRef}
                style={styles.web}
                originWhitelist={["*"]}
                source={{html: map.html, baseUrl: KAKAO_WEB_BASE_URL}}
                injectedJavaScriptBeforeContentLoaded={`window.__INITIAL__ = ${map.payload}; true;`}
                onMessage={map.handleWebViewMessage}
                javaScriptEnabled
                scrollEnabled={false}
            />
        </View>
    );
}
