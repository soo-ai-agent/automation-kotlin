---
name: kotlin-repository
description: 리포지토리 작성과 리뷰 규칙. storage db-core 의 JpaRepository 인터페이스, 쿼리 메서드 이름, 페이징, fetch join 과 N+1, Specification 분리를 다룰 때 사용한다. "조회 쿼리 추가", "쿼리가 느리다", "N+1" 요청에도 사용할 것.
---

# Repository

**자리:** `storage/db-core/.../storage/db/core/XxxRepository.kt`

## 저장소 접근은 여기서 끝난다

```kotlin
interface TodoRepository : JpaRepository<TodoEntity, Long> {
    fun findAllByMemberIdOrderByIdDesc(memberId: Long): List<TodoEntity>
    fun findByIdAndMemberId(id: Long, memberId: Long): TodoEntity?
    fun existsByMemberIdAndTitle(memberId: Long, title: String): Boolean
    fun deleteByIdAndMemberId(id: Long, memberId: Long): Long
}
```

- 이름으로 의도가 드러나게: `findBy...`, `existsBy...`, `save`, `deleteBy...`, `countBy...`.

- 반환 타입을 명시한다. 없을 수 있으면 `?`, 목록이면 `List<T>`.

- SQL·JPQL 은 이 모듈 밖으로 새지 않는다. 서비스·컨트롤러에 쿼리 문자열이 있으면 위반이다.

## 규칙

- **상한 없는 전체 조회를 만들지 않는다.** 목록은 조건이나 `Pageable` 을 받는다. 계약상 전체 반환이 맞다면 그 이유를 주석으로 남긴다.

- 연관관계를 함께 쓸 조회는 `@EntityGraph` 나 `join fetch` 로 한 번에 가져온다 (N+1 방지).

- 조건이 세 개를 넘거나 조합이 유동적이면 메서드 이름을 늘리지 말고 `Specification` 을 별도 파일(`XxxSpecs.kt`)로 분리한다.

- 벌크 갱신은 `@Modifying(clearAutomatically = true)` 와 함께 쓰고, 영속성 컨텍스트가 어긋날 수 있음을 인지한다.

- 소유자 스코프가 있는 데이터는 **조회 단계에서 소유자 조건을 건다**(`findByIdAndMemberId`). 조회 후 애플리케이션에서 비교하지 않는다.

## 적발 신호

| 신호 | 문제 | 심각도 |
|---|---|---|
| 소유자 조건 없이 id 로만 조회 후 코드에서 비교 | 권한 우회 위험 | Critical |
| 서비스·컨트롤러에 쿼리 문자열 | 저장소 격리 붕괴 | Critical |
| 벌크 `@Modifying` 에 컨텍스트 정리 없음 | 낡은 엔티티 사용 | Critical |
| 상한 없는 `findAll` 목록 조회 | 메모리·응답 폭증 | Important |
| 루프 안 단건 조회 | N+1 | Important |
| 이름이 의도를 감춤(`findData`) | 가독성 | Important |
| 조건이 많아 이름이 비대해진 메서드 | Specification 미분리 | Important |

## 체크리스트

- [ ] 메서드 이름이 조회 조건을 그대로 드러내는가

- [ ] 목록 조회에 조건이나 페이징이 있는가

- [ ] 연관관계 조회가 N+1 을 만들지 않는가

- [ ] 소유자 조건이 쿼리에 포함됐는가
