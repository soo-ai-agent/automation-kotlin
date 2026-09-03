package io.automation.core.todo.api.request

import io.automation.core.todo.domain.model.TodoUpdateCommand
import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.NotNull
import jakarta.validation.constraints.Size

data class TodoUpdateRequest(
    // 필드를 안 보낸 요청에서 null 이 가능함
    @field:NotBlank(message = "제목은 필수입니다")
    @field:Size(max = 200, message = "제목은 200자를 넘을 수 없습니다")
    val title: String?,
    // Boolean 을 non-null 로 두면 필드를 안 보낸 요청이 false 를 보낸 요청과 같아진다 (rules.md MUST)
    @field:NotNull(message = "완료 여부는 필수입니다")
    val done: Boolean?,
) {
    fun toCommand(): TodoUpdateCommand {
        // 검증 통과 뒤에만 불린다
        val validTitle: String = checkNotNull(title)
        val validDone: Boolean = checkNotNull(done)
        return TodoUpdateCommand(title = validTitle.trim(), done = validDone)
    }
}
