import {DetailStatus} from "../enums/user";
import {useCallback, useState} from "react";
import {getUserDetail} from "../services/userService";
import {UserResultMessages} from "../enums/user";
import type {User} from "../types/user";
import type {ServiceErrorHandler} from "../../common/hooks/useServiceErrorHandler";

/** 열림 여부·로딩 여부·사용자를 따로 두지 않는다. 세 상태가 한 값으로 표현되어 모순 조합이 없다. */
export type DetailState =
    | {status: DetailStatus.CLOSED}
    | {status: DetailStatus.LOADING}
    | {status: DetailStatus.LOADED; user: User};

const CLOSED_STATE: DetailState = {status: DetailStatus.CLOSED};

export function useUserDetail(handleError: ServiceErrorHandler) {
    const [detailState, setDetailState] = useState<DetailState>(CLOSED_STATE);

    const closeDetail = useCallback((): void => {
        setDetailState(CLOSED_STATE);
    }, []);

    const openDetail = useCallback(async (id: number): Promise<void> => {
        setDetailState({status: DetailStatus.LOADING});
        try {
            const loadedUser: User = await getUserDetail(id);
            setDetailState({status: DetailStatus.LOADED, user: loadedUser});
        } catch (error) {
            setDetailState(CLOSED_STATE);
            handleError(error, UserResultMessages.DETAIL_LOAD_ERROR);
        }
    }, [handleError]);

    return {detailState, openDetail, closeDetail};
}
