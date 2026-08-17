import {StyleSheet} from "react-native";
import {colors, spacing} from "../../common/lib/theme";

export const styles = StyleSheet.create({
    wrap: {
        alignItems: "center", borderTopWidth: 1, borderTopColor: colors.border,
        backgroundColor: colors.bgElevated,
    },
    placeholder: {
        justifyContent: "center", paddingVertical: spacing(4),
    },
    placeholderText: {
        color: colors.textMuted, fontSize: 12,
    },
});
