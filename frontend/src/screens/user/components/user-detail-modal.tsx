import {forwardRef, useImperativeHandle, type Ref} from "react";
import {Modal, Pressable, StyleSheet, Text, View} from "react-native";
import {UserResultMessages} from "@/constants";
import {useServiceErrorHandler} from "@/hooks/use-service-error-handler";
import {formatDateTime, formatOptionalDateTime} from "@/utils/format-date";
import {useStyles, type Colors, radius, spacing} from "@/theme";
import {DetailStatus, useUserDetail} from "../hooks/use-user-detail";

/** 부모에게서 받는 값이 없다. 여는 것은 ref 의 openDetail 이 한다. */
type UserDetailModalProps = Record<never, never>;

export interface UserDetailModalRef {
    openDetail: (id: number) => void;
}

function UserDetailModalBase(_props: UserDetailModalProps, ref: Ref<UserDetailModalRef>) {
    const styles = useStyles(createStyles);
    const {handleError} = useServiceErrorHandler();
    const {detailState, openDetail, closeDetail} = useUserDetail(handleError);

    useImperativeHandle(ref, () => ({openDetail}), [openDetail]);

    return (
        <Modal
            visible={detailState.status !== DetailStatus.CLOSED}
            transparent
            animationType="fade"
            onRequestClose={closeDetail}
        >
            <Pressable style={styles.backdrop} onPress={closeDetail}>
                {/* 내용을 눌러도 닫히지 않게 빈 onPress 로 터치를 흡수한다(RN 모달 관례). */}
                <Pressable
                    style={styles.sheet}
                    onPress={() => {}}
                    accessibilityViewIsModal
                    accessibilityLabel="사용자 상세"
                >
                    {detailState.status === DetailStatus.LOADING && (
                        <Text style={styles.stateText}>{UserResultMessages.DETAIL_LOADING}</Text>
                    )}

                    {detailState.status === DetailStatus.LOADED && (
                        <View style={styles.body}>
                            <Text style={styles.name}>{detailState.user.name}</Text>
                            <View style={styles.fieldRow}>
                                <Text style={styles.fieldLabel}>이메일</Text>
                                <Text style={styles.fieldValue}>{detailState.user.email}</Text>
                            </View>
                            <View style={styles.fieldRow}>
                                <Text style={styles.fieldLabel}>가입일</Text>
                                <Text style={styles.fieldValue}>
                                    {formatDateTime(detailState.user.createdAt)}
                                </Text>
                            </View>
                            <View style={styles.fieldRow}>
                                <Text style={styles.fieldLabel}>마지막 로그인</Text>
                                <Text style={styles.fieldValue}>
                                    {formatOptionalDateTime(detailState.user.lastLoginAt)}
                                </Text>
                            </View>
                        </View>
                    )}

                    <Pressable accessibilityRole="button" style={styles.closeButton} onPress={closeDetail}>
                        <Text style={styles.closeLabel}>닫기</Text>
                    </Pressable>
                </Pressable>
            </Pressable>
        </Modal>
    );
}

export const UserDetailModal = forwardRef(UserDetailModalBase);

const createStyles = (colors: Colors) => StyleSheet.create({
    backdrop: {
        flex: 1, alignItems: "center", justifyContent: "center", padding: spacing(6),
        backgroundColor: colors.backdrop,
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
