package io.automation.core.todo.domain.service

import io.automation.core.todo.domain.error.TodoNotFoundException
import io.automation.storage.db.core.TodoEntity
import io.automation.storage.db.core.TodoRepository
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.assertj.core.api.Assertions.assertThatThrownBy
import org.junit.jupiter.api.Test

class TodoRemoverTest {
    private val todoFinder: TodoFinder = mockk()
    private val todoRepository: TodoRepository = mockk(relaxed = true)
    private val todoRemover = TodoRemover(todoFinder, todoRepository)

    @Test
    fun `찾은 할 일을 지운다`() {
        val todo = TodoEntity(title = "장보기")
        every { todoFinder.getEntity(1L) } returns todo

        todoRemover.remove(1L)

        // 지우는 것이 이 클래스의 전부라, 호출 자체가 요구사항이다
        verify { todoRepository.delete(todo) }
    }

    @Test
    fun `없는 할 일을 지우려 하면 예외를 던진다`() {
        every { todoFinder.getEntity(1L) } throws TodoNotFoundException(1L)

        assertThatThrownBy { todoRemover.remove(1L) }
            .isInstanceOf(TodoNotFoundException::class.java)
    }
}
