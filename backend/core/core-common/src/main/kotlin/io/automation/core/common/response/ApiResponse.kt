package io.automation.core.common.response

import io.automation.core.common.error.ApiException
import io.automation.core.common.error.ErrorMessage

class ApiResponse<T> private constructor(
    val result: ResultType,
    val data: T? = null,
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
            return ApiResponse(ResultType.ERROR, null, ErrorMessage(e))
        }
    }
}
