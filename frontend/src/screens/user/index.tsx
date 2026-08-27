import {Link} from "expo-router";
import {Pressable, StyleSheet, Text, View} from "react-native";
import {SafeAreaView} from "react-native-safe-area-context";
import {AdBanner} from "@/components/ad-banner";
import {useStyles, type Colors, radius, spacing} from "@/theme";
import {UserDetailModal} from "./components/user-detail-modal";
import {UserTable} from "./components/user-table";
import {UserToolbar} from "./components/user-toolbar";
import {useUsers} from "./hooks/use-users";

export function User() {
    const {table, modalRefs} = useUsers();
    const {detailModalRef} = modalRefs;
    const styles = useStyles(createStyles);

    return (
        <SafeAreaView style={styles.container}>
            <View style={styles.header}>
                <Text style={styles.title}>사용자</Text>
                {/* 지도 화면을 들어냈다면 이 버튼을 지운다 (frontend/docs/map.md) */}
                <Link href="/map" asChild>
                    <Pressable accessibilityRole="button" style={styles.mapButton}>
                        <Text style={styles.mapButtonLabel}>지도</Text>
                    </Pressable>
                </Link>
            </View>

            <UserToolbar
                selectedCount={table.selectedIds.length}
                isLoading={table.isLoading}
                isDeleting={table.isDeleting}
                reloadUsers={table.reloadUsers}
                deleteSelected={table.deleteSelected}
            />

            <UserTable
                users={table.users}
                isLoading={table.isLoading}
                listState={table.listState}
                selectedIds={table.selectedIds}
                isAllSelected={table.isAllSelected}
                isDeleting={table.isDeleting}
                toggleSelect={table.toggleSelect}
                toggleSelectAll={table.toggleSelectAll}
                openDetail={table.openDetail}
                reloadUsers={table.reloadUsers}
                deleteOne={table.deleteOne}
            />

            <UserDetailModal ref={detailModalRef} />

            {/* 광고를 안 쓰는 앱이면 이 줄을 지운다 (frontend/docs/ads.md) */}
            <AdBanner />
        </SafeAreaView>
    );
}

const createStyles = (colors: Colors) => StyleSheet.create({
    container: {
        flex: 1, backgroundColor: colors.bg,
    },
    header: {
        flexDirection: "row", alignItems: "center", justifyContent: "space-between",
        paddingHorizontal: spacing(4), paddingVertical: spacing(3),
    },
    title: {
        color: colors.text, fontSize: 24, fontWeight: "800",
    },
    mapButton: {
        paddingHorizontal: spacing(3), paddingVertical: spacing(2), borderRadius: radius.sm,
        backgroundColor: colors.panel,
    },
    mapButtonLabel: {
        color: colors.text, fontSize: 14, fontWeight: "600",
    },
});
