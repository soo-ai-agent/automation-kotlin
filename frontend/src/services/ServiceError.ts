import {ErrorLevel} from "../enums/errorLevel";
export class ServiceError extends Error {
    constructor(
        message: string,
        readonly status: number,
        readonly level: ErrorLevel = ErrorLevel.ERROR,
    ) {
        super(message);
        this.name = "ServiceError";
    }
}
