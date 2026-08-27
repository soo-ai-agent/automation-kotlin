import {StyleSheet, Text, View} from "react-native";
import {MapResultMessages} from "@/constants";
import {useStyles, type Colors, spacing} from "@/theme";
import type {KakaoMapViewProps} from "./kakao-map-view.types";

/**
 * 웹 빌드용 대체 구현 — react-native-webview 가 웹을 지원하지 않아 자리 표시만 한다.
 * Metro 가 웹 번들에서 `.web.tsx` 를 자동으로 골라 가므로 호출부는 구분을 모른다.
 */
export function KakaoMapView({style}: KakaoMapViewProps) {
    const styles = useStyles(createStyles);
    return (
        <View style={[styles.fallback, style]}>
            <Text style={styles.fallbackText}>{MapResultMessages.WEB_UNSUPPORTED}</Text>
        </View>
    );
}

const createStyles = (colors: Colors) => StyleSheet.create({
    fallback: {
        alignItems: "center", justifyContent: "center", gap: spacing(2), padding: spacing(6),
        backgroundColor: colors.panel,
    },
    fallbackText: {
        color: colors.text, fontSize: 15, fontWeight: "600", textAlign: "center",
    },
});
