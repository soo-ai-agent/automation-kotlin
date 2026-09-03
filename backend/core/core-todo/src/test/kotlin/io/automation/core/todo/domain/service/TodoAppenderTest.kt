package io.automation.core.todo.domain.service

import io.automation.core.todo.domain.model.TodoCreateCommand
import io.automation.core.todo.domain.model.TodoResult
import io.automation.storage.db.core.TodoEntity
import io.automation.storage.db.core.TodoRepository
import io.mockk.every
import io.mockk.mockk
import org.assertj.core.api.Assertions.assertThat
import org.junit.jupiter.api.Test

class TodoAppenderTest {
    private val todoRepository: TodoRepository = mockk()
    private val todoAppender = TodoAppender(todoRepository)

    @Test
    fun `저장한 할 일을 미완료 상태로 돌려준다`() {
        every { todoRepository.save(any()) } returns TodoEntity(title = "장보기")

        val result: TodoResult = todoAppender.append(TodoCreateCommand("장보기"))

        assertThat(result.title).isEqualTo("장보기")
        assertThat(result.done).isFalse()
    }
}
