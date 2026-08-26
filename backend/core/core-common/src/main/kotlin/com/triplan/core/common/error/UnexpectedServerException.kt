package com.triplan.core.common.error

import org.springframework.http.HttpStatus

class UnexpectedServerException(
    cause: Throwable? = null,
) : ApiException(
    status = HttpStatus.INTERNAL_SERVER_ERROR,
    code = "UNEXPECTED_SERVER_ERROR",
    detail = "일시적인 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.",
    cause = cause,
)
