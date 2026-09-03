package io.automation.core.todo.domain.service

import io.automation.core.todo.domain.error.TodoNotFoundException
import io.automation.core.todo.domain.model.TodoResult
import io.automation.storage.db.core.TodoEntity
import io.automation.storage.db.core.TodoRepository
import org.springframework.stereotype.Component

@Component
class TodoFinder(
    private val todoRepository: TodoRepository,
) {
    fun list(): List<TodoResult> = todoRepository.findAllByOrderByIdDesc().map { it.toResult() }

    fun getById(todoId: Long): TodoResult = getEntity(todoId).toResult()

    /** 상태를 바꾸는 구현 레이어가 쓰는 통로다. 엔티티는 이 모듈 밖으로 나가지 않는다. */
    internal fun getEntity(todoId: Long): TodoEntity = todoRepository.findOneById(todoId) ?: throw TodoNotFoundException(todoId)
}
