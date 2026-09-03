package io.automation.core.todo.domain.model

data class TodoUpdateCommand(
    val title: String,
    val done: Boolean,
)
