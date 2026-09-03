package io.automation.core.todo.api.request

import io.automation.core.todo.domain.model.TodoCreateCommand
import org.assertj.core.api.Assertions.assertThat
import org.junit.jupiter.api.Test

class TodoCreateRequestTest {
    @Test
    fun `제목의 앞뒤 공백을 지워 넘긴다`() {
        val command: TodoCreateCommand = TodoCreateRequest(title = "  장보기  ").toCommand()

        assertThat(command.title).isEqualTo("장보기")
    }
}
