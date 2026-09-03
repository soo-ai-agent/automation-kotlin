package io.automation.core.todo.domain.service

import io.automation.core.todo.domain.error.TodoNotFoundException
import io.automation.core.todo.domain.model.TodoResult
import io.automation.core.todo.domain.model.TodoUpdateCommand
import io.automation.storage.db.core.TodoEntity
import io.mockk.every
import io.mockk.mockk
import org.assertj.core.api.Assertions.assertThat
import org.assertj.core.api.Assertions.assertThatThrownBy
import org.junit.jupiter.api.Test

class TodoUpdaterTest {
    private val todoFinder: TodoFinder = mockk()
    private val todoUpdater = TodoUpdater(todoFinder)

    @Test
    fun `제목을 바꾼다`() {
        every { todoFinder.getEntity(1L) } returns TodoEntity(title = "장보기")

        val result: TodoResult = todoUpdater.update(1L, TodoUpdateCommand(title = "청소하기", done = false))

        assertThat(result.title).isEqualTo("청소하기")
    }

    @Test
    fun `완료로 바꾼다`() {
        every { todoFinder.getEntity(1L) } returns TodoEntity(title = "장보기")

        val result: TodoResult = todoUpdater.update(1L, TodoUpdateCommand(title = "장보기", done = true))

        assertThat(result.done).isTrue()
    }

    @Test
    fun `완료를 되돌린다`() {
        every { todoFinder.getEntity(1L) } returns TodoEntity(title = "장보기", done = true)

        val result: TodoResult = todoUpdater.update(1L, TodoUpdateCommand(title = "장보기", done = false))

        assertThat(result.done).isFalse()
    }

    @Test
    fun `없는 할 일을 바꾸려 하면 예외를 던진다`() {
        every { todoFinder.getEntity(1L) } throws TodoNotFoundException(1L)

        assertThatThrownBy { todoUpdater.update(1L, TodoUpdateCommand(title = "장보기", done = true)) }
            .isInstanceOf(TodoNotFoundException::class.java)
    }
}
