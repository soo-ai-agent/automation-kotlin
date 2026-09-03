package io.automation.core.todo.api.request

import io.automation.core.todo.domain.model.TodoUpdateCommand
import org.assertj.core.api.Assertions.assertThat
import org.junit.jupiter.api.Test

class TodoUpdateRequestTest {
    @Test
    fun `제목의 앞뒤 공백을 지우고 완료 여부를 그대로 넘긴다`() {
        val command: TodoUpdateCommand = TodoUpdateRequest(title = "  장보기  ", done = true).toCommand()

        assertThat(command.title).isEqualTo("장보기")
        assertThat(command.done).isTrue()
    }
}
