---
name: kotlin-entity
description: JPA 엔티티 작성과 리뷰 규칙. storage db-core 의 @Entity 클래스, BaseEntity 상속, private set 과 행위 메서드, 애그리게이트 경계, 연관관계 페치 전략을 다룰 때 사용한다. "테이블 추가", "엔티티 상태 변경", "컬럼 추가" 요청에도 사용할 것.
---

# Entity

**자리:** `storage/db-core/.../storage/db/core/XxxEntity.kt`

## 상태는 스스로만 바꾼다

```kotlin
@Entity
@Table(name = "todo")
class TodoEntity(
    @Column(name = "member_id", nullable = false)
    val memberId: Long,

    @Column(name = "title", nullable = false, length = 200)
    var title: String,
        private set,

    @Column(name = "done", nullable = false)
    var done: Boolean = false,
        private set,
) : BaseEntity() {

    fun rename(newTitle: String) {
        require(newTitle.isNotBlank()) { "제목은 비어 있을 수 없습니다" }
        title = newTitle
    }

    fun toggle() {
        done = !done
    }
}
```

- 바뀌지 않는 값은 `val`. 바뀌는 값만 `var` + **`private set`**.
- **공개 세터를 만들지 않는다.** 밖에서 `entity.done = true` 가 가능하면 위반이다.
- 상태 변경 규칙과 불변식은 **엔티티 메서드에 캡슐화**한다. 검증 없이 대입만 하는 메서드는 세터와 같으니 만들지 않는다.
- 식별자·생성시각·수정시각은 `BaseEntity` 가 갖는다. 다시 선언하지 않는다.

## 애그리게이트

- 경계를 넘는 상태 변경은 **루트 엔티티를 통해** 수행한다. 자식 엔티티를 밖에서 직접 바꾸지 않는다.
- 자식 컬렉션은 `private` 으로 두고 읽기 전용 뷰만 노출한다.

```kotlin
@OneToMany(mappedBy = "order", cascade = [CascadeType.ALL], orphanRemoval = true)
private val _items: MutableList<OrderItemEntity> = mutableListOf()
val items: List<OrderItemEntity> get() = _items.toList()

fun addItem(product: Long, quantity: Int) {
    require(quantity > 0) { "수량은 1 이상이어야 합니다" }
    _items.add(OrderItemEntity(this, product, quantity))
}
```

## 매핑

- 연관관계는 전부 `FetchType.LAZY`. `@ManyToOne` 기본값이 EAGER 이므로 명시적으로 덮는다.
- `@Column` 에 `nullable`, `length` 를 명시한다. DB 제약을 애플리케이션 검증에 미루지 않는다.
- enum 은 `@Enumerated(EnumType.STRING)`. ORDINAL 은 값 추가 시 데이터가 깨진다.
- 조회 조건이 있는 컬럼에는 인덱스를 `@Table(indexes = [...])` 로 선언한다.
- 동시 수정이 걸리는 엔티티에는 `@Version` 으로 낙관적 락을 건다.

## 적발 신호

| 신호 | 문제 | 심각도 |
|---|---|---|
| 공개 세터(`var` 에 `private set` 없음) | 예측 불가능한 상태 변경 | Critical |
| 밖에서 프로퍼티 직접 대입 | 불변식 우회 | Critical |
| 자식 엔티티를 루트 밖에서 변경 | 애그리게이트 경계 붕괴 | Critical |
| `MutableList` 를 그대로 노출 | 내부 컬렉션 변형 | Critical |
| `@Enumerated` 기본값(ORDINAL) | 값 추가 시 데이터 파손 | Critical |
| `@ManyToOne` 에 LAZY 미지정 | 불필요한 조회·N+1 | Important |
| `nullable`·`length` 미지정 | DB 제약 부재 | Important |
| 검증 없이 대입만 하는 변경 메서드 | 세터와 동일 | Important |

## 체크리스트

- [ ] 모든 변경 가능 프로퍼티가 `private set` 인가
- [ ] 상태 변경이 규칙을 가진 행위 메서드로만 일어나는가
- [ ] 컬렉션이 읽기 전용으로 노출되는가
- [ ] 연관관계가 LAZY 이고 enum 이 STRING 인가
