import {Link, Stack} from "expo-router";
import {Pressable, StyleSheet, Text, View} from "react-native";
import {NotFoundMessages} from "@/constants";
import {useStyles, type Colors, radius, spacing} from "@/theme";

/**
 * 어느 라우트에도 걸리지 않는 주소에서 그려진다.
 * 이 파일이 없으면 Expo Router 의 개발용 "Unmatched Route" 화면이 사용자에게 그대로 보인다.
 */
export default function NotFoundRoute() {
    const styles = useStyles(createStyles);

    return (
        <View style={styles.container}>
            <Stack.Screen options={{title: NotFoundMessages.TITLE}} />
            <Text style={styles.title}>{NotFoundMessages.TITLE}</Text>
            <Text style={styles.body}>{NotFoundMessages.BODY}</Text>
            <Link href="/" asChild>
                <Pressable accessibilityRole="button" style={styles.button}>
                    <Text style={styles.buttonLabel}>{NotFoundMessages.GO_HOME}</Text>
                </Pressable>
            </Link>
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
    button: {
        marginTop: spacing(2), paddingHorizontal: spacing(5), paddingVertical: spacing(3),
        borderRadius: radius.sm, backgroundColor: colors.primary,
    },
    buttonLabel: {
        color: colors.primaryInk, fontSize: 15, fontWeight: "700",
    },
});
