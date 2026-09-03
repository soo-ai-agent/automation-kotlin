package io.automation.core.todo.domain.service

import io.automation.core.todo.domain.model.TodoCreateCommand
import io.automation.core.todo.domain.model.TodoResult
import io.automation.core.todo.domain.model.TodoUpdateCommand
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

/** 흐름과 트랜잭션 경계만 갖는다. 조회 조건·변환·상태 전이는 구현 레이어와 엔티티의 몫이다. */
@Service
class TodoService(
    private val todoFinder: TodoFinder,
    private val todoAppender: TodoAppender,
    private val todoUpdater: TodoUpdater,
    private val todoRemover: TodoRemover,
) {
    @Transactional(readOnly = true)
    fun list(): List<TodoResult> = todoFinder.list()

    @Transactional
    fun create(command: TodoCreateCommand): TodoResult = todoAppender.append(command)

    @Transactional
    fun update(todoId: Long, command: TodoUpdateCommand): TodoResult = todoUpdater.update(todoId, command)

    @Transactional
    fun delete(todoId: Long) = todoRemover.remove(todoId)
}
