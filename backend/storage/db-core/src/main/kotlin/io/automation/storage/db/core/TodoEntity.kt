package io.automation.storage.db.core

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.Table

@Entity
@Table(name = "todo")
class TodoEntity(
    // 바뀌는 값은 생성자에서 프로퍼티로 선언하지 않는다. 본문에서 선언해야 setter 를 좁힐 수 있다
    title: String,
    done: Boolean = false,
) : BaseEntity() {

    @Column(name = "title", nullable = false, length = 200)
    var title: String = title
        protected set

    @Column(name = "done", nullable = false)
    var done: Boolean = done
        protected set

    fun rename(newTitle: String) {
        require(newTitle.isNotBlank()) { "제목은 비어 있을 수 없습니다" }
        title = newTitle
    }

    fun complete() {
        done = true
    }

    fun reopen() {
        done = false
    }
}
