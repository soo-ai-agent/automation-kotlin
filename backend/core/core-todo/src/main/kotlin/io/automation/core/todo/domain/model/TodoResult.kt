package io.automation.core.todo.domain.model

import java.time.LocalDateTime

/** 도메인 밖으로 나가는 할 일 하나. 엔티티는 이 타입으로 바뀌어야 구현 레이어 위로 올라갈 수 있다. */
data class TodoResult(
    val id: Long,
    val title: String,
    val done: Boolean,
    val createdAt: LocalDateTime,
)
