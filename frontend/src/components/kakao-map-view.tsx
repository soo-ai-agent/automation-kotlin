import {StyleSheet, Text, View} from "react-native";
import {WebView} from "react-native-webview";
import {MapResultMessages} from "@/constants";
import {KAKAO_JS_KEY, KAKAO_WEB_BASE_URL} from "@/utils/config";
import {useKakaoMapView} from "@/hooks/use-kakao-map-view";
import {useStyles, type Colors, spacing} from "@/theme";
import type {KakaoMapViewProps} from "./kakao-map-view.types";

export function KakaoMapView({center, level, markers, style}: KakaoMapViewProps) {
    const styles = useStyles(createStyles);
    const {webViewRef, html, payload, handleWebViewMessage} = useKakaoMapView({center, level, markers});

    if (!KAKAO_JS_KEY) {
        return (
            <View style={[styles.fallback, style]}>
                <Text style={styles.fallbackText}>{MapResultMessages.KEY_MISSING}</Text>
                <Text style={styles.fallbackHint}>{MapResultMessages.KEY_MISSING_HINT}</Text>
            </View>
        );
    }

    return (
        <View style={[styles.container, style]}>
            <WebView
                ref={webViewRef}
                style={styles.web}
                originWhitelist={["*"]}
                source={{html: html, baseUrl: KAKAO_WEB_BASE_URL}}
                injectedJavaScriptBeforeContentLoaded={`window.__INITIAL__ = ${payload}; true;`}
                onMessage={handleWebViewMessage}
                javaScriptEnabled
                scrollEnabled={false}
            />
        </View>
    );
}

const createStyles = (colors: Colors) => StyleSheet.create({
    container: {
        overflow: "hidden", backgroundColor: colors.panel,
    },
    web: {
        flex: 1, backgroundColor: colors.panel,
    },
    fallback: {
        alignItems: "center", justifyContent: "center", gap: spacing(2), padding: spacing(6),
        backgroundColor: colors.panel,
    },
    fallbackText: {
        color: colors.text, fontSize: 15, fontWeight: "600", textAlign: "center",
    },
    fallbackHint: {
        color: colors.textDim, fontSize: 13, textAlign: "center",
    },
});
