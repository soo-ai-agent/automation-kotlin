package io.automation.core.todo.domain.service

import io.automation.core.todo.domain.error.TodoNotFoundException
import io.automation.core.todo.domain.model.TodoResult
import io.automation.storage.db.core.TodoEntity
import io.automation.storage.db.core.TodoRepository
import io.mockk.every
import io.mockk.mockk
import org.assertj.core.api.Assertions.assertThat
import org.assertj.core.api.Assertions.assertThatThrownBy
import org.junit.jupiter.api.Test

class TodoFinderTest {
    private val todoRepository: TodoRepository = mockk()
    private val todoFinder = TodoFinder(todoRepository)

    @Test
    fun `목록을 도메인 모델로 바꿔 돌려준다`() {
        every { todoRepository.findAllByOrderByIdDesc() } returns listOf(TodoEntity(title = "장보기"))

        val results: List<TodoResult> = todoFinder.list()

        assertThat(results).hasSize(1)
        assertThat(results[0].title).isEqualTo("장보기")
    }

    @Test
    fun `없는 할 일을 찾으면 예외를 던진다`() {
        every { todoRepository.findOneById(1L) } returns null

        assertThatThrownBy { todoFinder.getById(1L) }
            .isInstanceOf(TodoNotFoundException::class.java)
    }
}
