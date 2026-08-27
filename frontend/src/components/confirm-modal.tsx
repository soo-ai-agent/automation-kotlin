import {Modal, Pressable, StyleSheet, Text, View} from "react-native";
import type {ConfirmDialogOptions} from "@/utils/confirm-dialog";
import {useStyles, type Colors, radius, spacing} from "@/theme";

type ConfirmModalProps = {
    options: ConfirmDialogOptions;
    onCancel: () => void;
    onConfirm: () => void;
};

/** 앱 디자인의 공통 확인 팝업 — OS 기본 대화상자 대신 쓴다. 여는 창구는 `notify.confirm` 이다. */
export function ConfirmModal({options, onCancel, onConfirm}: ConfirmModalProps) {
    const styles = useStyles(createStyles);
    return (
        <Modal visible transparent animationType="fade" onRequestClose={onCancel}>
            <Pressable style={styles.backdrop} onPress={onCancel}>
                {/* 내용을 눌러도 닫히지 않게 빈 onPress 로 터치를 흡수한다(RN 모달 관례). */}
                <Pressable
                    style={styles.dialog}
                    onPress={() => {}}
                    accessibilityViewIsModal
                    accessibilityLabel={options.title}
                >
                    <Text style={styles.title}>{options.title}</Text>
                    {options.body !== "" && <Text style={styles.body}>{options.body}</Text>}

                    <View style={styles.actions}>
                        <Pressable
                            onPress={onCancel}
                            accessibilityRole="button"
                            style={styles.cancelButton}
                        >
                            <Text style={styles.cancelText}>{options.cancelText}</Text>
                        </Pressable>
                        <Pressable
                            onPress={onConfirm}
                            accessibilityRole="button"
                            style={[styles.confirmButton, options.destructive && styles.confirmButtonDanger]}
                        >
                            <Text style={styles.confirmText}>{options.confirmText}</Text>
                        </Pressable>
                    </View>
                </Pressable>
            </Pressable>
        </Modal>
    );
}

const createStyles = (colors: Colors) => StyleSheet.create({
    backdrop: {
        flex: 1, alignItems: "center", justifyContent: "center", padding: spacing(6),
        backgroundColor: colors.backdrop,
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
