import {Pressable, Text, View} from "react-native";
import {styles} from "./UserToolbar.styles";

type UserToolbarProps = {
    selectedCount: number;
    isLoading: boolean;
    isDeleting: boolean;
    reloadUsers: () => Promise<void>;
    deleteSelected: () => Promise<void>;
};

function UserToolbar({selectedCount, isLoading, isDeleting, reloadUsers, deleteSelected}: UserToolbarProps) {
    return (
        <View style={styles.toolbar}>
            <Text style={styles.count}>선택 {selectedCount}건</Text>
            <Pressable
                accessibilityRole="button"
                style={[styles.button, isDeleting && styles.buttonDisabled]}
                disabled={isDeleting}
                onPress={() => void deleteSelected()}
            >
                <Text style={styles.buttonLabel}>선택 삭제</Text>
            </Pressable>
            <Pressable
                accessibilityRole="button"
                style={[styles.button, isLoading && styles.buttonDisabled]}
                disabled={isLoading}
                onPress={() => void reloadUsers()}
            >
                <Text style={styles.buttonLabel}>새로고침</Text>
            </Pressable>
        </View>
    );
}

export default UserToolbar;
