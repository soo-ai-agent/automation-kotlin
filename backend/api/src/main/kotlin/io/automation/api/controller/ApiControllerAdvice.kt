package io.automation.api.controller

import io.automation.core.common.error.ApiException
import io.automation.core.common.error.ApiFieldError
import io.automation.core.common.error.RequestValidationException
import io.automation.core.common.error.UnexpectedServerException
import io.automation.core.common.response.ApiResponse
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import org.springframework.http.ResponseEntity
import org.springframework.http.converter.HttpMessageNotReadableException
import org.springframework.validation.FieldError
import org.springframework.web.bind.MethodArgumentNotValidException
import org.springframework.web.bind.annotation.ExceptionHandler
import org.springframework.web.bind.annotation.RestControllerAdvice

/**
 * 예외가 자기 응답(status·code·detail)을 들고 오므로 여기서는 값만 옮겨 담는다.
 * 새 도메인 예외를 더해도 핸들러는 늘지 않는다 — 늘어나는 것은 ApiException 을 상속할 수 없는 프레임워크 예외뿐이다.
 */
@RestControllerAdvice
class ApiControllerAdvice {
    private val log: Logger = LoggerFactory.getLogger(javaClass)

    @ExceptionHandler(ApiException::class)
    fun handleApiException(e: ApiException): ResponseEntity<ApiResponse<Any>> = respond(e)

    @ExceptionHandler(MethodArgumentNotValidException::class)
    fun handleValidationFailure(e: MethodArgumentNotValidException): ResponseEntity<ApiResponse<Any>> {
        val fieldErrors: MutableList<ApiFieldError> = mutableListOf()
        for (fieldError: FieldError in e.bindingResult.fieldErrors) {
            val message: String = fieldError.defaultMessage ?: "올바르지 않은 값입니다."
            fieldErrors.add(ApiFieldError(fieldError.field, message))
        }
        return respond(RequestValidationException(fieldErrors))
    }

    /** 본문이 없거나 JSON 이 깨진 요청. 핸들러가 없으면 500 으로 나간다. */
    @ExceptionHandler(HttpMessageNotReadableException::class)
    fun handleNotReadable(e: HttpMessageNotReadableException): ResponseEntity<ApiResponse<Any>> = respond(RequestValidationException(listOf(ApiFieldError("body", "요청 본문을 읽을 수 없습니다."))))

    // 최상위 경계다. 여기서 잡지 않으면 스프링 기본 응답이 나가 프론트가 래퍼를 벗기지 못한다.
    @ExceptionHandler(Exception::class)
    fun handleException(e: Exception): ResponseEntity<ApiResponse<Any>> = respond(UnexpectedServerException(e))

    private fun respond(e: ApiException): ResponseEntity<ApiResponse<Any>> {
        // 사용자가 잘못 보낸 요청(4xx)은 정상 동작이다. ERROR 로 찍으면 진짜 장애가 로그에 묻힌다.
        if (e.status.is5xxServerError) {
            log.error("{} : {}", e.code, e.message, e)
        } else {
            log.warn("{} : {}", e.code, e.message)
        }
        return ResponseEntity(ApiResponse.error(e), e.status)
    }
}
