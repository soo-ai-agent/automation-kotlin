import {forwardRef, useImperativeHandle, type Ref} from "react";
import {Modal, Pressable, Text, View} from "react-native";
import {useUserDetail} from "../hooks/useUserDetail";
import {DetailStatus} from "../enums/user";
import {useServiceErrorHandler} from "../../common/hooks/useServiceErrorHandler";
import {formatDateTime, formatOptionalDateTime} from "../../common/utils/formatDate";
import {styles} from "./UserDetailModal.styles";

/** 부모에게서 받는 값이 없다. 여는 것은 ref 의 openDetail 이 한다. */
type UserDetailModalProps = Record<never, never>;

export interface UserDetailModalRef {
    openDetail: (id: number) => void;
}

function UserDetailModal(_props: UserDetailModalProps, ref: Ref<UserDetailModalRef>) {
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
                        <Text style={styles.stateText}>사용자 정보를 불러오는 중입니다.</Text>
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

export default forwardRef(UserDetailModal);
