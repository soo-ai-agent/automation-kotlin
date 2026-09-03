package io.automation.core.todo.api.response

import io.automation.core.todo.domain.model.TodoResult
import java.time.LocalDateTime

data class TodoResponse(
    val id: Long,
    val title: String,
    val done: Boolean,
    val createdAt: LocalDateTime,
) {
    companion object {
        fun from(result: TodoResult): TodoResponse = TodoResponse(
            id = result.id,
            title = result.title,
            done = result.done,
            createdAt = result.createdAt,
        )
    }
}
