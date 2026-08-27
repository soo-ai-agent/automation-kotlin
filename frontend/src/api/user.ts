import {UserResultMessages, SessionResultMessages} from "@/constants";
import {apiClient, type ApiResult} from "./client";
import {ErrorLevel, ServiceError} from "@/utils/service-error";

const USERS = "/api/v1/users";

export type User = {
    id: number;
    name: string;
    email: string;
    createdAt: string;
    lastLoginAt: string | null;   // 한 번도 로그인하지 않은 사용자는 null로 내려온다.
};

/** 삭제는 "이미 없음"도 정상 결과다 — 실패로 던지지 않고 결과로 돌려준다. */
export enum DeleteUserOutcome {
    SUCCESS = "SUCCESS",
    ALREADY_MISSING = "ALREADY_MISSING",
}

export async function getUserList(): Promise<User[]> {
    const result: ApiResult<User[]> = await apiClient.get<User[]>({path: USERS});

    if (result.ok) {
        return result.data;
    }
    if (result.status === 401) {
        throw new ServiceError(SessionResultMessages.EXPIRED, 401, ErrorLevel.WARNING);
    }
    if (result.status === 403) {
        throw new ServiceError(UserResultMessages.FORBIDDEN, 403, ErrorLevel.WARNING);
    }
    throw new ServiceError(UserResultMessages.LIST_LOAD_ERROR, result.status, ErrorLevel.ERROR);
}

export async function getUserDetail(id: number): Promise<User> {
    const result: ApiResult<User> = await apiClient.get<User>({path: `${USERS}/${id}`});

    if (result.ok) {
        return result.data;
    }
    if (result.status === 401) {
        throw new ServiceError(SessionResultMessages.EXPIRED, 401, ErrorLevel.WARNING);
    }
    if (result.status === 403) {
        throw new ServiceError(UserResultMessages.FORBIDDEN, 403, ErrorLevel.WARNING);
    }
    if (result.status === 404) {
        throw new ServiceError(UserResultMessages.DETAIL_NOT_FOUND, 404, ErrorLevel.WARNING);
    }
    throw new ServiceError(UserResultMessages.DETAIL_LOAD_ERROR, result.status, ErrorLevel.ERROR);
}

export async function deleteUser(id: number): Promise<DeleteUserOutcome> {
    const result: ApiResult<void> = await apiClient.delete<void>({path: `${USERS}/${id}`});

    if (result.ok) {
        return DeleteUserOutcome.SUCCESS;
    }
    if (result.status === 404) {
        return DeleteUserOutcome.ALREADY_MISSING;
    }
    if (result.status === 401) {
        throw new ServiceError(SessionResultMessages.EXPIRED, 401, ErrorLevel.WARNING);
    }
    if (result.status === 403) {
        throw new ServiceError(UserResultMessages.FORBIDDEN, 403, ErrorLevel.WARNING);
    }
    throw new ServiceError(UserResultMessages.DELETE_ERROR, result.status, ErrorLevel.ERROR);
}

export async function deleteUsers(ids: number[]): Promise<DeleteUserOutcome> {
    // 경로에 동사를 넣지 않는다(rules.md MUST) — 지울 대상은 질의 문자열로 고른다.
    const result: ApiResult<void> = await apiClient.delete<void>({
        path: `${USERS}?ids=${ids.join(",")}`,
    });

    if (result.ok) {
        return DeleteUserOutcome.SUCCESS;
    }
    if (result.status === 404) {
        return DeleteUserOutcome.ALREADY_MISSING;
    }
    if (result.status === 401) {
        throw new ServiceError(SessionResultMessages.EXPIRED, 401, ErrorLevel.WARNING);
    }
    if (result.status === 403) {
        throw new ServiceError(UserResultMessages.FORBIDDEN, 403, ErrorLevel.WARNING);
    }
    throw new ServiceError(UserResultMessages.DELETE_ERROR, result.status, ErrorLevel.ERROR);
}
