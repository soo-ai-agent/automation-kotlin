import {useEffect, useState} from "react";
import {formatAppInfoLine, loadAppInfo} from "../services/appInfo";

/**
 * 스플래시 표시 중 1회 조회해 하단 표기줄을 만든다 — 처음엔 빌드 내장 앱 버전만, 서버 응답이 오면
 * 서버 버전을 덧붙인다. 실패는 서비스가 null 로 수렴하므로 에러 상태가 없다(생략이 곧 에러 처리).
 */
export function useAppInfo(): {infoLine: string | null} {
    const [infoLine, setInfoLine] = useState<string | null>(formatAppInfoLine(null));

    useEffect(() => {
        let active: boolean = true;
        void loadAppInfo().then((info) => {
            if (active) {
                setInfoLine(formatAppInfoLine(info));
            }
        });
        return () => {
            active = false;
        };
    }, []);

    return {infoLine};
}
