package io.automation.core.todo.domain.service

import io.automation.core.todo.domain.model.TodoCreateCommand
import io.automation.core.todo.domain.model.TodoResult
import io.automation.storage.db.core.TodoEntity
import io.automation.storage.db.core.TodoRepository
import org.springframework.stereotype.Component

@Component
class TodoAppender(
    private val todoRepository: TodoRepository,
) {
    fun append(command: TodoCreateCommand): TodoResult {
        val saved: TodoEntity = todoRepository.save(TodoEntity(title = command.title))
        return saved.toResult()
    }
}
