import {StyleSheet, Text, View} from "react-native";
import {useAppInfo} from "@/hooks/use-app-info";
import {useStyles, type Colors, spacing} from "@/theme";

type SplashScreenProps = {
    /** 스플래시가 실제로 그려진 순간 — 네이티브 스플래시를 내리는 신호다 (use-splash-gate). */
    onVisible: () => void;
};

export function SplashScreen({onVisible}: SplashScreenProps) {
    const styles = useStyles(createStyles);
    const {infoLine} = useAppInfo();

    return (
        <View style={styles.container} onLayout={onVisible}>
            <Text style={styles.title}>frontend</Text>
            <Text style={styles.description}>프로젝트 이름과 소개 문구를 여기에 넣는다</Text>
            {infoLine !== null && <Text style={styles.version}>{infoLine}</Text>}
        </View>
    );
}

const createStyles = (colors: Colors) => StyleSheet.create({
    container: {
        flex: 1, alignItems: "center", justifyContent: "center", backgroundColor: colors.bg,
    },
    title: {
        color: colors.text, fontSize: 32, fontWeight: "800", letterSpacing: 1,
    },
    description: {
        marginTop: spacing(3), color: colors.textDim, fontSize: 15, textAlign: "center",
    },
    version: {
        position: "absolute", bottom: spacing(12), color: colors.textMuted, fontSize: 12,
        fontWeight: "500",
    },
});
