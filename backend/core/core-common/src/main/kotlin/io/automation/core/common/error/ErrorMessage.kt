package io.automation.core.common.error

/**
 * 응답의 error 자리에 실리는 모양이다. 프론트 `src/api/client.ts` 의 ErrorMessageDTO 와 1:1 로 맞춘다
 * — 필드 이름을 바꾸면 프론트가 벗기지 못한다 (CONTRACT.md).
 */
class ErrorMessage private constructor(
    val code: String,
    val message: String,
    val data: Any? = null,
) {
    constructor(e: ApiException) : this(
        code = e.code,
        message = e.detail,
        // 필드별 사유가 없으면 자리를 비운다
        data = e.fieldErrors.ifEmpty { null },
    )
}
