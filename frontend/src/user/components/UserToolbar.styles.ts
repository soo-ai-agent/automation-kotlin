import {StyleSheet} from "react-native";
import {colors, radius, spacing} from "../../common/lib/theme";

export const styles = StyleSheet.create({
    toolbar: {
        flexDirection: "row", alignItems: "center", gap: spacing(2),
        paddingHorizontal: spacing(4), paddingBottom: spacing(3),
    },
    count: {
        flex: 1, color: colors.textDim, fontSize: 14,
    },
    button: {
        paddingHorizontal: spacing(3), paddingVertical: spacing(2), borderRadius: radius.sm,
        backgroundColor: colors.panel,
    },
    buttonDisabled: {
        opacity: 0.5,
    },
    buttonLabel: {
        color: colors.text, fontSize: 14, fontWeight: "600",
    },
});
