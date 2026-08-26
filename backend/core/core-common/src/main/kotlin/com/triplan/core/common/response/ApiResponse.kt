package com.triplan.core.common.response

import com.triplan.core.common.error.ApiException

class ApiResponse<T> private constructor(
    val result: ResultType,
    // 실패 응답에는 null 이 가능함
    val data: T? = null,
    // 성공 응답에는 null 이 가능함
    val error: ErrorMessage? = null,
) {
    companion object {
        fun success(): ApiResponse<Any> {
            return ApiResponse(ResultType.SUCCESS, null, null)
        }

        fun <S> success(data: S): ApiResponse<S> {
            return ApiResponse(ResultType.SUCCESS, data, null)
        }

        fun <S> error(e: ApiException): ApiResponse<S> {
            return ApiResponse(ResultType.ERROR, null, ErrorMessage(e.code, e.detail, e.fieldErrors.ifEmpty { null }))
        }
    }
}
