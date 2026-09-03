package io.automation.storage.db.core

import org.springframework.data.jpa.repository.JpaRepository

interface TodoRepository : JpaRepository<TodoEntity, Long> {
    fun findAllByOrderByIdDesc(): List<TodoEntity>

    /** findByIdOrNull 은 최상위 확장 함수라 목으로 바꿀 수 없다. 파생 쿼리로 선언한다. */
    fun findOneById(id: Long): TodoEntity?
}
