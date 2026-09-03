package io.automation.core.common.error

import org.springframework.http.HttpStatus

/**
 * 모든 도메인 예외의 베이스. 응답에 나갈 값을 예외가 스스로 들고 온다.
 * 그래서 ApiControllerAdvice 는 예외 종류를 묻지 않고 값만 옮겨 담는다 — 새 예외를 더해도 핸들러는 늘지 않는다.
 */
abstract class ApiException(
    val status: HttpStatus,
    val code: String,
    val detail: String,
    val fieldErrors: List<ApiFieldError> = emptyList(),
    message: String = detail,
    cause: Throwable? = null,
) : RuntimeException(message, cause)
