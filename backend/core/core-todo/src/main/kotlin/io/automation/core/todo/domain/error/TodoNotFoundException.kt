package io.automation.core.todo.domain.error

import io.automation.core.common.error.ApiException
import org.springframework.http.HttpStatus

class TodoNotFoundException(todoId: Long) :
    ApiException(
        status = HttpStatus.NOT_FOUND,
        code = "TODO_NOT_FOUND",
        detail = "할 일을 찾을 수 없습니다.",
        message = "할 일이 없다: id=$todoId",
    )
