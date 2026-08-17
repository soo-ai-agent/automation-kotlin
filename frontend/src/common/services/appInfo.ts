import Constants from "expo-constants";
import {appInfo} from "../api/appInfo";
import {AppInfoLabel} from "../enums/appInfo";
import type {ApiResult} from "../lib/apiClient";
import type {AppInfo} from "../types/appInfo";

// 앱 버전 — 빌드에 박힌 값(app.json)이라 네트워크 없이 항상 표시할 수 있다.
// expoConfig 는 임베드 설정이 없는 실행 형태에서 null 이 가능해 빈 문자열로 수렴한다.
export const APP_VERSION: string = Constants.expoConfig?.version ?? "";

/**
 * 스플래시용 서버 정보 1회 조회. 스플래시는 관문이 아니다 — 어떤 실패(네트워크·비2xx·엔드포인트 없음)든
 * 진입을 막지 않도록 null 로 수렴하고, 호출부는 null 이면 서버 조각 표시만 생략한다.
 */
export async function loadAppInfo(): Promise<AppInfo | null> {
    let result: ApiResult<AppInfo>;
    try {
        result = await appInfo.get();
    } catch {
        return null;
    }
    if (!result.ok) {
        return null;
    }
    return result.data;
}

/**
 * 스플래시 하단 한 줄("앱 v1.0.0 · 서버 v0.0.1"). 앱 조각은 빌드 내장 버전이라 서버 응답과 무관하게
 * 표시하고, 빈 값 조각은 생략한다. 둘 다 비면 null — 호출부는 줄 자체를 그리지 않는다.
 */
export function formatAppInfoLine(info: AppInfo | null): string | null {
    const parts: string[] = [];
    if (APP_VERSION) {
        parts.push(`${AppInfoLabel.APP} v${APP_VERSION}`);
    }
    if (info && info.serverVersion) {
        parts.push(`${AppInfoLabel.SERVER} v${info.serverVersion}`);
    }
    return parts.length > 0 ? parts.join(" · ") : null;
}
