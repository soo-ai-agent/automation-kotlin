import {apiClient, type ApiResult} from "../../lib/apiClient";
import type {User} from "../types/user";

const USERS = "/api/v1/users";

export const user = {
    list(): Promise<ApiResult<User[]>> {
        return apiClient.get<User[]>({path: USERS});
    },

    detail(id: number): Promise<ApiResult<User>> {
        return apiClient.get<User>({path: `${USERS}/${id}`});
    },

    delete(id: number): Promise<ApiResult<void>> {
        return apiClient.delete<void>({path: `${USERS}/${id}`});
    },

    deleteBulk(ids: number[]): Promise<ApiResult<void>> {
        return apiClient.post<void>({path: `${USERS}/bulk-delete`, body: {ids}});
    },
};
