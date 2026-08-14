import {ErrorLevel} from "../enums/errorLevel";
import {notify} from "../lib/notify";
import {ServiceError} from "./ServiceError";

export function handleServiceError(
    error: unknown,   // catch 예외는 타입 보장이 없다 — 이 함수가 instanceof 로 좁히는 단일 판정 지점이다.
    handleSessionExpired: () => void,
    fallbackMessage: string,
): void {
    if (!(error instanceof ServiceError)) {
        console.error(fallbackMessage, error);
        notify.error(fallbackMessage);
        return;
    }
    if (error.status === 401) {
        handleSessionExpired();
        return;
    }
    if (error.level === ErrorLevel.WARNING) {
        notify.warning(error.message);
        return;
    }
    notify.error(error.message);
}
