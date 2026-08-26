package com.triplan.core.common.error

import org.springframework.http.HttpStatus

abstract class ApiException(
    val status: HttpStatus,
    val code: String,
    val detail: String,
    val fieldErrors: List<ApiFieldError> = emptyList(),
    message: String = detail,
    cause: Throwable? = null,
) : RuntimeException(message, cause)
