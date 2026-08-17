import {NavigationContainer} from "@react-navigation/native";
import {createNativeStackNavigator} from "@react-navigation/native-stack";
import {SafeAreaProvider, initialWindowMetrics} from "react-native-safe-area-context";
import {StatusBar} from "expo-status-bar";
import {SplashScreen} from "./src/splash/components/SplashScreen";
import {useSplashGate} from "./src/splash/hooks/useSplashGate";
import {ConfirmDialogHost} from "./src/common/components/modal/ConfirmDialogHost";
import {colors} from "./src/common/lib/theme";
import User from "./src/user/screens/User";
import MapScreen from "./src/map/screens/Map";
import type {RootStackParamList} from "./src/common/types/navigation";

const Stack = createNativeStackNavigator<RootStackParamList>();

export default function App() {
    const {isSplashVisible} = useSplashGate();

    if (isSplashVisible) {
        return (
            <SafeAreaProvider initialMetrics={initialWindowMetrics}>
                <StatusBar style="dark" />
                <SplashScreen />
            </SafeAreaProvider>
        );
    }

    return (
        <SafeAreaProvider initialMetrics={initialWindowMetrics}>
            <StatusBar style="dark" />
            <NavigationContainer>
                <Stack.Navigator
                    initialRouteName="User"
                    screenOptions={{headerShown: false, contentStyle: {backgroundColor: colors.bg}}}
                >
                    <Stack.Screen name="User" component={User} />
                    {/* 지도 화면을 들어냈다면 아래 한 줄을 지운다 (src/map/README.md) */}
                    <Stack.Screen name="Map" component={MapScreen} />
                </Stack.Navigator>
            </NavigationContainer>
            {/* 확인 팝업 호스트는 앱 루트에 하나만 — 어느 화면에서 불러도 이 자리에 그려진다. */}
            <ConfirmDialogHost />
        </SafeAreaProvider>
    );
}
