package io.automation.core.todo.domain.service

import io.automation.storage.db.core.TodoEntity
import io.automation.storage.db.core.TodoRepository
import org.springframework.stereotype.Component

@Component
class TodoRemover(
    private val todoFinder: TodoFinder,
    private val todoRepository: TodoRepository,
) {
    fun remove(todoId: Long) {
        val todo: TodoEntity = todoFinder.getEntity(todoId)
        todoRepository.delete(todo)
    }
}
