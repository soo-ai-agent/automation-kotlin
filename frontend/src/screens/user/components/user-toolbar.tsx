import {Pressable, StyleSheet, Text, View} from "react-native";
import {useStyles, type Colors, radius, spacing} from "@/theme";

type UserToolbarProps = {
    selectedCount: number;
    isLoading: boolean;
    isDeleting: boolean;
    reloadUsers: () => Promise<void>;
    deleteSelected: () => Promise<void>;
};

export function UserToolbar({selectedCount, isLoading, isDeleting, reloadUsers, deleteSelected}: UserToolbarProps) {
    const styles = useStyles(createStyles);
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

const createStyles = (colors: Colors) => StyleSheet.create({
    toolbar: {
        flexDirection: "row", alignItems: "center", gap: spacing(2),
        paddingHorizontal: spacing(4), paddingBottom: spacing(3),
    },
    count: {
        flex: 1, color: colors.textDim, fontSize: 14,
    },
    button: {
        paddingHorizontal: spacing(3), paddingVertical: spacing(2), borderRadius: radius.sm,
        backgroundColor: colors.panel,
    },
    buttonDisabled: {
        opacity: 0.5,
    },
    buttonLabel: {
        color: colors.text, fontSize: 14, fontWeight: "600",
    },
});
