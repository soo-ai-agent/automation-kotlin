import {Pressable, StyleSheet, Text, View} from "react-native";
import {SafeAreaView} from "react-native-safe-area-context";
import {KakaoMapView} from "@/components/kakao-map-view";
import type {MapMarker} from "@/components/kakao-map-view.types";
import {useStyles, type Colors, radius, spacing} from "@/theme";
import {useMapBack} from "./hooks/use-map-back";

/** 예시 중심점(서울시청). 실제 화면을 만들 때는 훅이 내려 주는 값으로 바꾼다. */
const EXAMPLE_CENTER = {lat: 37.5665, lng: 126.978};
const EXAMPLE_MARKERS: MapMarker[] = [{...EXAMPLE_CENTER, name: "서울시청"}];

export function Map() {
    const {goBack} = useMapBack();
    const styles = useStyles(createStyles);

    return (
        <SafeAreaView style={styles.container}>
            <View style={styles.header}>
                <Pressable accessibilityRole="button" style={styles.backButton} onPress={goBack}>
                    <Text style={styles.backLabel}>← 뒤로</Text>
                </Pressable>
                <Text style={styles.title}>지도</Text>
            </View>
            <KakaoMapView center={EXAMPLE_CENTER} level={4} markers={EXAMPLE_MARKERS} style={styles.map} />
        </SafeAreaView>
    );
}

const createStyles = (colors: Colors) => StyleSheet.create({
    container: {
        flex: 1, backgroundColor: colors.bg,
    },
    header: {
        flexDirection: "row", alignItems: "center", gap: spacing(3),
        paddingHorizontal: spacing(4), paddingVertical: spacing(3),
    },
    backButton: {
        paddingHorizontal: spacing(3), paddingVertical: spacing(2), borderRadius: radius.sm,
        backgroundColor: colors.panel,
    },
    backLabel: {
        color: colors.text, fontSize: 14, fontWeight: "600",
    },
    title: {
        color: colors.text, fontSize: 20, fontWeight: "800",
    },
    map: {
        flex: 1,
    },
});
