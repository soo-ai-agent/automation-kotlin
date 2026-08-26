package com.triplan.api.controller

import com.triplan.core.common.error.ApiException
import com.triplan.core.common.error.ApiFieldError
import com.triplan.core.common.error.RequestValidationException
import com.triplan.core.common.error.UnexpectedServerException
import com.triplan.core.common.response.ApiResponse
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import org.springframework.http.ResponseEntity
import org.springframework.http.converter.HttpMessageNotReadableException
import org.springframework.web.bind.MethodArgumentNotValidException
import org.springframework.web.bind.annotation.ExceptionHandler
import org.springframework.web.bind.annotation.RestControllerAdvice

@RestControllerAdvice
class ApiControllerAdvice {
    private val log: Logger = LoggerFactory.getLogger(javaClass)

    @ExceptionHandler(ApiException::class)
    fun handleApiException(e: ApiException): ResponseEntity<ApiResponse<Any>> {
        return respond(e)
    }

    @ExceptionHandler(MethodArgumentNotValidException::class)
    fun handleValidationFailure(e: MethodArgumentNotValidException): ResponseEntity<ApiResponse<Any>> {
        val fieldErrors: MutableList<ApiFieldError> = mutableListOf()
        for (fieldError in e.bindingResult.fieldErrors) {
            val message: String = fieldError.defaultMessage ?: "올바르지 않은 값입니다."
            fieldErrors.add(ApiFieldError(fieldError.field, message))
        }
        return respond(RequestValidationException(fieldErrors, cause = e))
    }

    @ExceptionHandler(HttpMessageNotReadableException::class)
    fun handleUnreadableMessage(e: HttpMessageNotReadableException): ResponseEntity<ApiResponse<Any>> {
        return respond(RequestValidationException(emptyList(), cause = e))
    }

    // 전역 최후 경계 — 포괄 catch 는 여기서만 허용한다
    @ExceptionHandler(Exception::class)
    fun handleException(e: Exception): ResponseEntity<ApiResponse<Any>> {
        return respond(UnexpectedServerException(cause = e))
    }

    private fun respond(e: ApiException): ResponseEntity<ApiResponse<Any>> {
        if (e.status.is5xxServerError) {
            log.error("ApiException : {}", e.message, e)
        } else {
            log.warn("ApiException : {}", e.message, e)
        }
        return ResponseEntity(ApiResponse.error(e), e.status)
    }
}
