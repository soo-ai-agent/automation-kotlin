import {Text, View} from "react-native";
import {useAppInfo} from "../hooks/useAppInfo";
import {styles} from "./SplashScreen.styles";

export function SplashScreen() {
    const {infoLine} = useAppInfo();

    return (
        <View style={styles.container}>
            <Text style={styles.title}>frontend</Text>
            <Text style={styles.description}>프로젝트 이름과 소개 문구를 여기에 넣는다</Text>
            {infoLine !== null && <Text style={styles.version}>{infoLine}</Text>}
        </View>
    );
}
