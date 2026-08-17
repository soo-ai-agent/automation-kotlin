import {useCallback} from "react";
import {notify} from "../lib/notify";
import {handleServiceError} from "../services/serviceErrorHandler";
import {SessionResultMessages} from "../enums/session";

// catch 로 들어온 예외는 JS 가 타입을 보장하지 않아 unknown 이 정확하다. 판정은 handleServiceError 가 한다.
export type ServiceErrorHandler = (error: unknown, fallbackMessage: string) => void;

export function useServiceErrorHandler() {
    // 로그인 화면이 아직 없어 안내만 한다 — 도입하면 여기서 로그인 화면으로 보낸다(고치는 곳은 이 함수 하나).
    const handleSessionExpired = useCallback((): void => {
        notify.warning(SessionResultMessages.EXPIRED);
    }, []);

    const handleError: ServiceErrorHandler = useCallback(
        (error, fallbackMessage) => {   // 타입은 위 ServiceErrorHandler 선언이 보장한다.
            handleServiceError(error, handleSessionExpired, fallbackMessage);
        },
        [handleSessionExpired],
    );

    return {handleError};
}
