import {StyleSheet} from "react-native";
import {colors, radius, spacing} from "../../lib/theme";

export const styles = StyleSheet.create({
    backdrop: {
        flex: 1, alignItems: "center", justifyContent: "center", padding: spacing(6),
        backgroundColor: "rgba(15, 23, 42, 0.5)",
    },
    dialog: {
        width: "100%", maxWidth: 320, padding: spacing(6), borderRadius: radius.md,
        borderWidth: 1, borderColor: colors.border, backgroundColor: colors.bg,
    },
    title: {
        color: colors.text, fontSize: 18, fontWeight: "700", textAlign: "center",
    },
    body: {
        marginTop: spacing(3), color: colors.textDim, fontSize: 14, lineHeight: 21,
        textAlign: "center",
    },
    actions: {
        flexDirection: "row", gap: spacing(3), marginTop: spacing(6),
    },
    cancelButton: {
        flex: 1, height: 48, alignItems: "center", justifyContent: "center",
        borderRadius: radius.sm, backgroundColor: colors.panel,
    },
    cancelText: {
        color: colors.text, fontSize: 15, fontWeight: "700",
    },
    confirmButton: {
        flex: 1, height: 48, alignItems: "center", justifyContent: "center",
        borderRadius: radius.sm, backgroundColor: colors.primary,
    },
    confirmButtonDanger: {
        backgroundColor: colors.danger,
    },
    confirmText: {
        color: colors.primaryInk, fontSize: 15, fontWeight: "700",
    },
});
