package io.automation.storage.db.core

import org.assertj.core.api.Assertions.assertThat
import org.assertj.core.api.Assertions.assertThatThrownBy
import org.junit.jupiter.api.Test

class TodoEntityTest {
    @Test
    fun `제목을 바꾼다`() {
        val todo = TodoEntity(title = "장보기")

        todo.rename("청소하기")

        assertThat(todo.title).isEqualTo("청소하기")
    }

    @Test
    fun `빈 제목으로는 바꿀 수 없다`() {
        val todo = TodoEntity(title = "장보기")

        assertThatThrownBy { todo.rename("   ") }
            .isInstanceOf(IllegalArgumentException::class.java)
    }

    @Test
    fun `완료로 바꾼다`() {
        val todo = TodoEntity(title = "장보기")

        todo.complete()

        assertThat(todo.done).isTrue()
    }

    @Test
    fun `완료를 되돌린다`() {
        val todo = TodoEntity(title = "장보기", done = true)

        todo.reopen()

        assertThat(todo.done).isFalse()
    }
}
