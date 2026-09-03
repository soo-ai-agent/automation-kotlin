package io.automation.core.common.error

import org.springframework.http.HttpStatus

/** 우리가 예상하지 못한 실패. 원인을 잃지 않도록 cause 를 안고 간다. */
class UnexpectedServerException(cause: Throwable? = null) :
    ApiException(
        status = HttpStatus.INTERNAL_SERVER_ERROR,
        code = "UNEXPECTED_ERROR",
        detail = "일시적인 문제가 발생했습니다. 잠시 후 다시 시도해 주세요.",
        message = "예상하지 못한 오류",
        cause = cause,
    )
