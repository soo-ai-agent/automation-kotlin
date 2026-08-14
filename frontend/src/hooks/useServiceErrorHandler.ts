import {useCallback} from "react";
import {notify} from "../lib/notify";
import {handleServiceError} from "../services/serviceErrorHandler";
import {SessionResultMessages} from "../enums/session";

const LOGIN_PATH: string = import.meta.env.VITE_LOGIN_PATH ?? "/login";   // 값은 루트 .env

// catch 로 들어온 예외는 JS 가 타입을 보장하지 않아 unknown 이 정확하다. 판정은 handleServiceError 가 한다.
export type ServiceErrorHandler = (error: unknown, fallbackMessage: string) => void;

export function useServiceErrorHandler() {
    const handleSessionExpired = useCallback((): void => {
        notify.warning(SessionResultMessages.EXPIRED);
        window.location.href = LOGIN_PATH;
    }, []);

    const handleError: ServiceErrorHandler = useCallback(
        (error, fallbackMessage) => {   // 타입은 위 ServiceErrorHandler 선언이 보장한다.
            handleServiceError(error, handleSessionExpired, fallbackMessage);
        },
        [handleSessionExpired],
    );

    return {handleError};
}
