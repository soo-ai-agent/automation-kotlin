import {apiClient, type ApiResult} from "../../common/lib/apiClient";
import type {AppInfo} from "../types/appInfo";

const APP_INFO = "/api/v1/app-info";

export const appInfo = {
    get(): Promise<ApiResult<AppInfo>> {
        return apiClient.get<AppInfo>({path: APP_INFO});
    },
};
