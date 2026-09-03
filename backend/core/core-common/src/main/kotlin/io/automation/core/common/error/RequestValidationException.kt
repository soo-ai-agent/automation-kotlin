package io.automation.core.common.error

import org.springframework.http.HttpStatus

/** 프레임워크 검증 실패(@Valid)를 우리 예외로 옮긴 것. 응답을 만드는 자리를 한 곳으로 유지한다. */
class RequestValidationException(fieldErrors: List<ApiFieldError>) :
    ApiException(
        status = HttpStatus.BAD_REQUEST,
        code = "INVALID_REQUEST",
        detail = "요청 값을 확인해 주세요.",
        fieldErrors = fieldErrors,
        message = "요청 검증 실패",
    )
