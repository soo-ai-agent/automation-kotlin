import {FlatList, Pressable, StyleSheet, Text, View} from "react-native";
import {UserResultMessages} from "@/constants";
import {ListStatus, type ListState} from "@/utils/list-state";
import {formatDateTime, formatOptionalDateTime} from "@/utils/format-date";
import type {User} from "@/api/user";
import {useStyles, type Colors, radius, spacing} from "@/theme";

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

export function UserTable({
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
    const styles = useStyles(createStyles);
    if (isLoading) {
        return <Text style={styles.stateText}>{UserResultMessages.LIST_LOADING}</Text>;
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
    const styles = useStyles(createStyles);
    return (
        <Pressable
            accessibilityRole="checkbox"
            accessibilityLabel={label}
            // accessibilityState 는 react-native-web 이 웹으로 내보내지 않는다(forwardedProps 에 없음).
            // aria-checked 는 RN 0.86 과 웹이 둘 다 지원해 한 줄로 양쪽을 만족한다.
            aria-checked={checked}
            style={[styles.selectBox, checked && styles.selectBoxChecked]}
            onPress={onToggle}
        >
            {checked && <Text style={styles.selectBoxMark}>✓</Text>}
        </Pressable>
    );
}

const createStyles = (colors: Colors) => StyleSheet.create({
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
