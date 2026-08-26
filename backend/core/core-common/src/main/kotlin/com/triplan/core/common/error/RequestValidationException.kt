package com.triplan.core.common.error

import org.springframework.http.HttpStatus

class RequestValidationException(
    fieldErrors: List<ApiFieldError>,
    cause: Throwable? = null,
) : ApiException(
    status = HttpStatus.BAD_REQUEST,
    code = "INVALID_REQUEST",
    detail = "요청 값을 확인해 주세요.",
    fieldErrors = fieldErrors,
    message = "요청 검증 실패",
    cause = cause,
)
