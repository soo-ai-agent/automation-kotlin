package io.automation.core.common.error

/** 어느 필드가 왜 거절됐는지. 검증 실패 응답의 data 에 실린다. */
data class ApiFieldError(
    val field: String,
    val message: String,
)
