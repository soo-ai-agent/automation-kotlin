import {DeleteUserOutcome, UserResultMessages} from "../enums/user";
import {SessionResultMessages} from "../../common/enums/session";
import {ErrorLevel} from "../../common/enums/errorLevel";
import {user} from "../api/user";
import type {ApiResult} from "../../common/lib/apiClient";
import type {User} from "../types/user";
import {ServiceError} from "../../common/services/ServiceError";

export async function getUserList(): Promise<User[]> {
    const result: ApiResult<User[]> = await user.list();

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
    const result: ApiResult<User> = await user.detail(id);

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
    const result: ApiResult<void> = await user.delete(id);

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
    const result: ApiResult<void> = await user.deleteBulk(ids);

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
