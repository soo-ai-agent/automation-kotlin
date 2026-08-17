import {FlatList, Pressable, Text, View} from "react-native";
import {type ListState} from "../../common/lib/listState";
import {ListStatus} from "../../common/enums/listStatus";
import type {User} from "../types/user";
import {formatDateTime, formatOptionalDateTime} from "../../common/utils/formatDate";
import {styles} from "./UserTable.styles";

type UserTableProps = {
    users: User[];
    isLoading: boolean;
    listState: ListState;
    selectedIds: number[];
    isAllSelected: boolean;
    isDeleting: boolean;
    toggleSelect: (id: number) => void;
    toggleSelectAll: () => void;
    openDetail: (id: number) => void;
    reloadUsers: () => Promise<void>;
    deleteOne: (id: number) => Promise<void>;
};

function UserTable({
    users,
    isLoading,
    listState,
    selectedIds,
    isAllSelected,
    isDeleting,
    toggleSelect,
    toggleSelectAll,
    openDetail,
    reloadUsers,
    deleteOne,
}: UserTableProps) {
    if (isLoading) {
        return <Text style={styles.stateText}>사용자 목록을 불러오는 중입니다.</Text>;
    }

    if (listState.status === ListStatus.ERROR) {
        return (
            <View style={styles.stateBox}>
                <Text style={styles.stateText}>{listState.message}</Text>
                <Pressable
                    accessibilityRole="button"
                    style={styles.retryButton}
                    onPress={() => void reloadUsers()}
                >
                    <Text style={styles.retryLabel}>다시 시도</Text>
                </Pressable>
            </View>
        );
    }

    if (listState.status === ListStatus.EMPTY) {
        return <Text style={styles.stateText}>{listState.message}</Text>;
    }

    return (
        <FlatList
            data={users}
            keyExtractor={(eachUser: User) => String(eachUser.id)}
            contentContainerStyle={styles.list}
            ListHeaderComponent={
                <View style={styles.headerRow}>
                    <SelectBox label="전체 선택" checked={isAllSelected} onToggle={toggleSelectAll} />
                    <Text style={styles.headerLabel}>전체 선택</Text>
                </View>
            }
            renderItem={({item}) => (
                <Pressable
                    accessibilityRole="button"
                    style={styles.row}
                    onPress={() => openDetail(item.id)}
                >
                    <SelectBox
                        label={`${item.name} 선택`}
                        checked={selectedIds.includes(item.id)}
                        onToggle={() => toggleSelect(item.id)}
                    />
                    <View style={styles.rowBody}>
                        <Text style={styles.name}>{item.name}</Text>
                        <Text style={styles.email}>{item.email}</Text>
                        <Text style={styles.dates}>
                            가입 {formatDateTime(item.createdAt)} · 마지막 로그인{" "}
                            {formatOptionalDateTime(item.lastLoginAt)}
                        </Text>
                    </View>
                    <Pressable
                        accessibilityRole="button"
                        style={[styles.deleteButton, isDeleting && styles.deleteButtonDisabled]}
                        disabled={isDeleting}
                        onPress={() => void deleteOne(item.id)}
                    >
                        <Text style={styles.deleteLabel}>삭제</Text>
                    </Pressable>
                </Pressable>
            )}
        />
    );
}

type SelectBoxProps = {
    label: string;
    checked: boolean;
    onToggle: () => void;
};

/** RN 에는 체크박스가 없어 Pressable 로 만든다 — 접근성 role/state 로 체크박스임을 알린다. */
function SelectBox({label, checked, onToggle}: SelectBoxProps) {
    return (
        <Pressable
            accessibilityRole="checkbox"
            accessibilityLabel={label}
            accessibilityState={{checked}}
            style={[styles.selectBox, checked && styles.selectBoxChecked]}
            onPress={onToggle}
        >
            {checked && <Text style={styles.selectBoxMark}>✓</Text>}
        </Pressable>
    );
}

export default UserTable;
