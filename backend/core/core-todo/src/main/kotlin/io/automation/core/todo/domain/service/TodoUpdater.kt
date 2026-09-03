package io.automation.core.todo.domain.service

import io.automation.core.todo.domain.model.TodoResult
import io.automation.core.todo.domain.model.TodoUpdateCommand
import io.automation.storage.db.core.TodoEntity
import org.springframework.stereotype.Component

@Component
class TodoUpdater(
    private val todoFinder: TodoFinder,
) {
    /** 식별자를 받아 스스로 찾는다 — 서비스가 엔티티를 들고 있으면 엔티티가 위로 새어 나간다. */
    fun update(todoId: Long, command: TodoUpdateCommand): TodoResult {
        val todo: TodoEntity = todoFinder.getEntity(todoId)
        todo.rename(command.title)
        if (command.done) {
            todo.complete()
        } else {
            todo.reopen()
        }
        return todo.toResult()
    }
}
