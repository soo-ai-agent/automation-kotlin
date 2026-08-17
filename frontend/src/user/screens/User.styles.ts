import {StyleSheet} from "react-native";
import {colors, radius, spacing} from "../../common/lib/theme";

export const styles = StyleSheet.create({
    container: {
        flex: 1, backgroundColor: colors.bg,
    },
    header: {
        flexDirection: "row", alignItems: "center", justifyContent: "space-between",
        paddingHorizontal: spacing(4), paddingVertical: spacing(3),
    },
    title: {
        color: colors.text, fontSize: 24, fontWeight: "800",
    },
    mapButton: {
        paddingHorizontal: spacing(3), paddingVertical: spacing(2), borderRadius: radius.sm,
        backgroundColor: colors.panel,
    },
    mapButtonLabel: {
        color: colors.text, fontSize: 14, fontWeight: "600",
    },
});
