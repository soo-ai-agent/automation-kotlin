package io.automation.core.todo.api.controller

import io.automation.core.common.response.ApiResponse
import io.automation.core.todo.api.request.TodoCreateRequest
import io.automation.core.todo.api.request.TodoUpdateRequest
import io.automation.core.todo.api.response.TodoResponse
import io.automation.core.todo.domain.model.TodoResult
import io.automation.core.todo.domain.service.TodoService
import jakarta.validation.Valid
import org.springframework.http.HttpStatus
import org.springframework.web.bind.annotation.DeleteMapping
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.PutMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.ResponseStatus
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/api/v1/todos")
class TodoController(
    private val todoService: TodoService,
) {
    @GetMapping
    fun list(): ApiResponse<List<TodoResponse>> {
        val results: List<TodoResult> = todoService.list()
        return ApiResponse.success(results.map(TodoResponse::from))
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    fun create(@Valid @RequestBody request: TodoCreateRequest): ApiResponse<TodoResponse> {
        val result: TodoResult = todoService.create(request.toCommand())
        return ApiResponse.success(TodoResponse.from(result))
    }

    @PutMapping("/{todoId}")
    fun update(
        @PathVariable todoId: Long,
        @Valid @RequestBody request: TodoUpdateRequest,
    ): ApiResponse<TodoResponse> {
        val result: TodoResult = todoService.update(todoId, request.toCommand())
        return ApiResponse.success(TodoResponse.from(result))
    }

    @DeleteMapping("/{todoId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    fun delete(@PathVariable todoId: Long) {
        todoService.delete(todoId)
    }
}
