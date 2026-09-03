package io.automation.core.todo.api.request

import io.automation.core.todo.domain.model.TodoCreateCommand
import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Size

data class TodoCreateRequest(
    // 필드를 안 보낸 요청에서 null 이 가능함
    @field:NotBlank(message = "제목은 필수입니다")
    @field:Size(max = 200, message = "제목은 200자를 넘을 수 없습니다")
    val title: String?,
) {
    fun toCommand(): TodoCreateCommand {
        // @NotBlank 통과 뒤에만 불린다
        val validTitle: String = checkNotNull(title)
        return TodoCreateCommand(title = validTitle.trim())
    }
}
