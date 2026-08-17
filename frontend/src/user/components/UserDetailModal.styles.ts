import {StyleSheet} from "react-native";
import {colors, radius, spacing} from "../../common/lib/theme";

export const styles = StyleSheet.create({
    backdrop: {
        flex: 1, alignItems: "center", justifyContent: "center", padding: spacing(6),
        backgroundColor: "rgba(15, 23, 42, 0.5)",
    },
    sheet: {
        alignSelf: "stretch", gap: spacing(4), padding: spacing(5), borderRadius: radius.md,
        backgroundColor: colors.bg,
    },
    stateText: {
        color: colors.textDim, fontSize: 14, textAlign: "center", padding: spacing(4),
    },
    body: {
        gap: spacing(3),
    },
    name: {
        color: colors.text, fontSize: 20, fontWeight: "800",
    },
    fieldRow: {
        gap: spacing(1),
    },
    fieldLabel: {
        color: colors.textMuted, fontSize: 12, fontWeight: "600",
    },
    fieldValue: {
        color: colors.text, fontSize: 15,
    },
    closeButton: {
        alignItems: "center", paddingVertical: spacing(3), borderRadius: radius.sm,
        backgroundColor: colors.panel,
    },
    closeLabel: {
        color: colors.text, fontSize: 14, fontWeight: "600",
    },
});
