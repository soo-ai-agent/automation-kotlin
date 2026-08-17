import {Pressable, Text, View} from "react-native";
import {SafeAreaView} from "react-native-safe-area-context";
import type {NativeStackScreenProps} from "@react-navigation/native-stack";
import {KakaoMapView} from "../components/KakaoMapView";
import {styles} from "./Map.styles";
import type {RootStackParamList} from "../../common/types/navigation";
import type {MapMarker} from "../types/map";

type MapProps = NativeStackScreenProps<RootStackParamList, "Map">;

/** 예시 중심점(서울시청). 실제 화면을 만들 때는 훅이 내려 주는 값으로 바꾼다. */
const EXAMPLE_CENTER = {lat: 37.5665, lng: 126.978};
const EXAMPLE_MARKERS: MapMarker[] = [{...EXAMPLE_CENTER, name: "서울시청"}];

const MapScreen = ({navigation}: MapProps) => {
    return (
        <SafeAreaView style={styles.container}>
            <View style={styles.header}>
                <Pressable
                    accessibilityRole="button"
                    style={styles.backButton}
                    onPress={() => navigation.goBack()}
                >
                    <Text style={styles.backLabel}>← 뒤로</Text>
                </Pressable>
                <Text style={styles.title}>지도</Text>
            </View>
            <KakaoMapView center={EXAMPLE_CENTER} level={4} markers={EXAMPLE_MARKERS} style={styles.map} />
        </SafeAreaView>
    );
};

export default MapScreen;
