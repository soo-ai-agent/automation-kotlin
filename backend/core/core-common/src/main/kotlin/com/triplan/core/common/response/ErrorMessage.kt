package com.triplan.core.common.response

import com.triplan.core.common.error.ApiFieldError

class ErrorMessage(
    val code: String,
    val message: String,
    // 필드 단위 사유가 없는 실패에는 null 이 가능함
    val data: List<ApiFieldError>? = null,
)
