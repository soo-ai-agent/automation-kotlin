import {Pressable, StyleSheet, Text, View} from "react-native";
import {ErrorBoundaryMessages} from "@/constants";
import {useStyles, type Colors, radius, spacing} from "@/theme";

type ErrorScreenProps = {
    /** 개발 중에만 보여 준다 — 사용자에게 스택을 그대로 내보이지 않는다. */
    error: Error;
    onRetry: () => void;
};

/** 렌더 중 예외가 났을 때 빈 화면 대신 그려진다. 붙이는 자리는 `src/app/_layout.tsx` 의 ErrorBoundary. */
export function ErrorScreen({error, onRetry}: ErrorScreenProps) {
    const styles = useStyles(createStyles);

    return (
        <View style={styles.container}>
            <Text style={styles.title}>{ErrorBoundaryMessages.TITLE}</Text>
            <Text style={styles.body}>{ErrorBoundaryMessages.BODY}</Text>
            {__DEV__ && <Text style={styles.detail}>{error.message}</Text>}
            <Pressable accessibilityRole="button" style={styles.button} onPress={onRetry}>
                <Text style={styles.buttonLabel}>{ErrorBoundaryMessages.RETRY}</Text>
            </Pressable>
        </View>
    );
}

const createStyles = (colors: Colors) => StyleSheet.create({
    container: {
        flex: 1, alignItems: "center", justifyContent: "center", gap: spacing(3),
        padding: spacing(6), backgroundColor: colors.bg,
    },
    title: {
        color: colors.text, fontSize: 20, fontWeight: "800", textAlign: "center",
    },
    body: {
        color: colors.textDim, fontSize: 14, textAlign: "center",
    },
    detail: {
        color: colors.danger, fontSize: 12, textAlign: "center",
    },
    button: {
        marginTop: spacing(2), paddingHorizontal: spacing(5), paddingVertical: spacing(3),
        borderRadius: radius.sm, backgroundColor: colors.primary,
    },
    buttonLabel: {
        color: colors.primaryInk, fontSize: 15, fontWeight: "700",
    },
});
