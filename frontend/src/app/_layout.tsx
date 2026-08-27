import {useEffect} from "react";
import {Stack, type ErrorBoundaryProps} from "expo-router";
import {StatusBar} from "expo-status-bar";
import {SafeAreaProvider, initialWindowMetrics} from "react-native-safe-area-context";
import {ConfirmDialogHost} from "@/components/confirm-dialog-host";
import {ErrorScreen} from "@/components/error-screen";
import {SplashScreen} from "@/components/splash-screen";
import {useSplashGate} from "@/hooks/use-splash-gate";
import {initializeAds} from "@/utils/admob";
import {useColors, type Colors} from "@/theme";

export default function RootLayout() {
    const colors: Colors = useColors();
    const {isSplashVisible, handleSplashVisible} = useSplashGate();

    // 광고 SDK 초기화는 앱당 한 번 — 이 줄이 없으면 지면이 영영 비어 있다 (frontend/docs/ads.md).
    useEffect(initializeAds, []);

    if (isSplashVisible) {
        return (
            <SafeAreaProvider initialMetrics={initialWindowMetrics}>
                <StatusBar style="auto" />
                <SplashScreen onVisible={handleSplashVisible} />
            </SafeAreaProvider>
        );
    }

    return (
        <SafeAreaProvider initialMetrics={initialWindowMetrics}>
            <StatusBar style="auto" />
            <Stack screenOptions={{headerShown: false, contentStyle: {backgroundColor: colors.bg}}} />
            {/* 확인 팝업 호스트는 루트에 하나만 — 어느 화면에서 불러도 이 자리에 그려진다. */}
            <ConfirmDialogHost />
        </SafeAreaProvider>
    );
}

/**
 * 렌더 중 예외를 여기서 받는다 — Expo Router 가 레이아웃의 이 export 를 찾아 쓴다.
 * 없으면 화면이 통째로 비어 사용자가 무슨 일이 났는지 알 수 없다.
 */
export function ErrorBoundary({error, retry}: ErrorBoundaryProps) {
    return <ErrorScreen error={error} onRetry={retry} />;
}
