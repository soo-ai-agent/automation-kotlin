import {Modal, Pressable, Text, View} from "react-native";
import type {ConfirmDialogOptions} from "../../lib/confirmDialog";
import {styles} from "./ConfirmModal.styles";

type ConfirmModalProps = {
    options: ConfirmDialogOptions;
    onCancel: () => void;
    onConfirm: () => void;
};

/** 앱 디자인의 공통 확인 팝업 — OS 기본 대화상자 대신 쓴다. 여는 창구는 `notify.confirm` 이다. */
export function ConfirmModal({options, onCancel, onConfirm}: ConfirmModalProps) {
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
