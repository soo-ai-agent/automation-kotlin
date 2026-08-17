import {StyleSheet} from "react-native";
import {colors, radius, spacing} from "../../common/lib/theme";

export const styles = StyleSheet.create({
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
