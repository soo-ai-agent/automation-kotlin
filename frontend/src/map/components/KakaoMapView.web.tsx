import {Text, View} from "react-native";
import {styles} from "./KakaoMapView.styles";
import type {KakaoMapViewProps} from "./KakaoMapView.types";

/**
 * 웹 빌드용 대체 구현 — react-native-webview 가 웹을 지원하지 않아 자리 표시만 한다.
 * Metro 가 웹 번들에서 `.web.tsx` 를 자동으로 골라 가므로 호출부는 구분을 모른다.
 */
export function KakaoMapView({style}: KakaoMapViewProps) {
    return (
        <View style={[styles.fallback, style]}>
            <Text style={styles.fallbackText}>지도는 네이티브 앱(iOS·Android)에서 표시됩니다.</Text>
        </View>
    );
}
