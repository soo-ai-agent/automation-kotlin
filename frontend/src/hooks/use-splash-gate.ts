import {useCallback, useEffect, useRef, useState} from "react";
import * as ExpoSplashScreen from "expo-splash-screen";
import {loadSplashAssets} from "@/utils/splash-assets";

/**
 * 네이티브 스플래시가 자동으로 사라지지 않게 막는다 — 첫 렌더보다 먼저 실행되어야 해서 모듈 최상단이다.
 * 이걸 안 하면 JS 가 뜨기 전에 네이티브 스플래시가 내려가 흰 화면이 한 번 스친다.
 * 이미 내려간 뒤에 불리면 거부되는데, 그때는 할 일이 없으므로 삼킨다. (웹에서는 아무 일도 하지 않는다)
 */
void ExpoSplashScreen.preventAutoHideAsync().catch(() => {});

/** 스플래시 최소 노출 시간(ms). 에셋이 이보다 빨리 준비돼도 로고가 깜빡이고 지나가지 않게 잡아 둔다. */
const SPLASH_MIN_DURATION_MS = 1200;

/**
 * 스플래시를 언제 걷을지 정한다 — **에셋 준비와 최소 노출 시간을 둘 다** 기다린다.
 * 시간만 재면 느린 기기에서 준비도 안 된 화면이 열리고, 준비만 재면 빠른 기기에서 로고가 스치고 만다.
 */
export function useSplashGate(): {isSplashVisible: boolean; handleSplashVisible: () => void} {
    const [isSplashVisible, setIsSplashVisible] = useState(true);
    const isNativeSplashHidden = useRef(false);

    useEffect(() => {
        let isActive: boolean = true;
        let timer: ReturnType<typeof setTimeout> | undefined;

        const minimumDelay = new Promise<void>((resolve) => {
            timer = setTimeout(resolve, SPLASH_MIN_DURATION_MS);
        });

        void Promise.all([loadSplashAssets(), minimumDelay]).then(() => {
            if (isActive) {
                setIsSplashVisible(false);
            }
        });

        return () => {
            isActive = false;
            clearTimeout(timer);
        };
    }, []);

    /**
     * 우리 스플래시가 실제로 그려진 뒤에 네이티브 스플래시를 내린다.
     * 먼저 내리면 두 스플래시 사이에 빈 화면이 보인다. 한 번만 부르면 되므로 ref 로 잠근다.
     */
    const handleSplashVisible = useCallback((): void => {
        if (isNativeSplashHidden.current) {
            return;
        }
        isNativeSplashHidden.current = true;
        void ExpoSplashScreen.hideAsync().catch(() => {});
    }, []);

    return {isSplashVisible, handleSplashVisible};
}
