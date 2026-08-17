import {StyleSheet} from "react-native";
import {colors, spacing} from "../../common/lib/theme";

export const styles = StyleSheet.create({
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
