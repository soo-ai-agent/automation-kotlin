import {Pressable, Text, View} from "react-native";
import {SafeAreaView} from "react-native-safe-area-context";
import type {NativeStackScreenProps} from "@react-navigation/native-stack";
import UserTable from "../components/UserTable";
import UserToolbar from "../components/UserToolbar";
import UserDetailModal from "../components/UserDetailModal";
import {AdBanner} from "../../ads/components/AdBanner";
import {useUsers} from "../hooks/useUsers";
import {styles} from "./User.styles";
import type {RootStackParamList} from "../../common/types/navigation";

type UserProps = NativeStackScreenProps<RootStackParamList, "User">;

const User = ({navigation}: UserProps) => {
    const {table, modalRefs} = useUsers();

    return (
        <SafeAreaView style={styles.container}>
            <View style={styles.header}>
                <Text style={styles.title}>사용자</Text>
                {/* 지도 화면을 들어냈다면 이 버튼을 지운다 (src/map/README.md) */}
                <Pressable
                    accessibilityRole="button"
                    style={styles.mapButton}
                    onPress={() => navigation.navigate("Map")}
                >
                    <Text style={styles.mapButtonLabel}>지도</Text>
                </Pressable>
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

            <UserDetailModal ref={modalRefs.detailModalRef} />

            {/* 광고를 안 쓰는 앱이면 이 줄을 지운다 (src/ads/README.md) */}
            <AdBanner />
        </SafeAreaView>
    );
};

export default User;
