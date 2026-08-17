import {useEffect, useState} from "react";

/** 스플래시 최소 노출 시간(ms). 버전 조회가 이보다 빨라도 로고가 깜빡이고 지나가지 않게 잡아 둔다. */
const SPLASH_DURATION_MS = 1200;

export function useSplashGate(): {isSplashVisible: boolean} {
    const [isSplashVisible, setIsSplashVisible] = useState(true);

    useEffect(() => {
        const timer = setTimeout(() => setIsSplashVisible(false), SPLASH_DURATION_MS);
        return () => clearTimeout(timer);
    }, []);

    return {isSplashVisible};
}
