package io.automation.core.todo.domain.service

import io.automation.core.todo.domain.model.TodoResult
import io.automation.storage.db.core.TodoEntity

/**
 * 엔티티 ↔ 도메인 모델 변환이 사는 유일한 자리다.
 * 도메인 모델에 두면 모델이 storage 를 import 하게 되고, storage 에 두면 storage 가 core 를 import 하게 된다.
 */
internal fun TodoEntity.toResult(): TodoResult = TodoResult(
    id = id,
    title = title,
    done = done,
    createdAt = createdAt,
)
