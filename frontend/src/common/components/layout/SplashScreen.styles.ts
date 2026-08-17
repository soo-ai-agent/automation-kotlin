import {StyleSheet} from "react-native";
import {colors, spacing} from "../../lib/theme";

export const styles = StyleSheet.create({
    container: {
        flex: 1, alignItems: "center", justifyContent: "center", backgroundColor: colors.bg,
    },
    title: {
        color: colors.text, fontSize: 32, fontWeight: "800", letterSpacing: 1,
    },
    description: {
        marginTop: spacing(3), color: colors.textDim, fontSize: 15, textAlign: "center",
    },
    version: {
        position: "absolute", bottom: spacing(12), color: colors.textMuted, fontSize: 12,
        fontWeight: "500",
    },
});
