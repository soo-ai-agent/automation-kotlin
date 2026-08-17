import {StyleSheet} from "react-native";
import {colors, radius, spacing} from "../../common/lib/theme";

export const styles = StyleSheet.create({
    stateText: {
        color: colors.textDim, fontSize: 14, textAlign: "center", padding: spacing(6),
    },
    stateBox: {
        alignItems: "center", gap: spacing(3), padding: spacing(6),
    },
    retryButton: {
        paddingHorizontal: spacing(4), paddingVertical: spacing(2), borderRadius: radius.sm,
        backgroundColor: colors.primary,
    },
    retryLabel: {
        color: colors.primaryInk, fontSize: 14, fontWeight: "600",
    },
    list: {
        paddingHorizontal: spacing(4), paddingBottom: spacing(6),
    },
    headerRow: {
        flexDirection: "row", alignItems: "center", gap: spacing(2), paddingVertical: spacing(2),
        borderBottomWidth: 1, borderBottomColor: colors.border,
    },
    headerLabel: {
        color: colors.textDim, fontSize: 13,
    },
    row: {
        flexDirection: "row", alignItems: "center", gap: spacing(3), paddingVertical: spacing(3),
        borderBottomWidth: 1, borderBottomColor: colors.border,
    },
    rowBody: {
        flex: 1, gap: spacing(1),
    },
    name: {
        color: colors.text, fontSize: 16, fontWeight: "700",
    },
    email: {
        color: colors.textDim, fontSize: 14,
    },
    dates: {
        color: colors.textMuted, fontSize: 12,
    },
    deleteButton: {
        paddingHorizontal: spacing(3), paddingVertical: spacing(2), borderRadius: radius.sm,
        backgroundColor: colors.panel,
    },
    deleteButtonDisabled: {
        opacity: 0.5,
    },
    deleteLabel: {
        color: colors.danger, fontSize: 13, fontWeight: "600",
    },
    selectBox: {
        width: 22, height: 22, borderRadius: 6, borderWidth: 2, borderColor: colors.border,
        alignItems: "center", justifyContent: "center", backgroundColor: colors.bg,
    },
    selectBoxChecked: {
        borderColor: colors.primary, backgroundColor: colors.primary,
    },
    selectBoxMark: {
        color: colors.primaryInk, fontSize: 14, fontWeight: "800", lineHeight: 16,
    },
});
