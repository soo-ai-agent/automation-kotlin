---
name: kotlin-domain-service
description: 도메인 서비스 작성과 리뷰 규칙. core/domain 의 Service 클래스, 유스케이스 오케스트레이션, @Transactional 트랜잭션 경계, 구현 레이어 조합을 다룰 때 사용한다. "비즈니스 로직", "서비스 추가", "트랜잭션 경계" 요청에도 사용할 것.
---

# Domain Service

**자리:** `core/core-<도메인>/.../<도메인>/domain/<도메인>/XxxService.kt`

## 역할 — 흐름과 트랜잭션 경계만

유스케이스의 **흐름과 트랜잭션 경계**를 담당한다. 상세 구현은 구현 레이어에 맡기고, 서비스는 순서대로 조립한다.

**왜 리포지토리를 직접 부르지 않나.** 서비스에 조회 조건과 변환 코드까지 들어가면, 다음 유스케이스가 같은 조회를 필요로 할 때 복사하게 된다. 조회를 `TodoFinder` 로 한 번 빼 두면 여러 서비스가 같은 것을 쓴다.

그래서 서비스를 읽으면 **무엇을 어떤 순서로 하는지**만 보이고, 어떻게 하는지는 안 보이는 것이 정상이다.

```kotlin
@Service
class TodoService(
    private val todoFinder: TodoFinder,
    private val todoAppender: TodoAppender,
) {
    @Transactional(readOnly = true)
    fun list(memberId: Long): List<TodoResult> = todoFinder.listByMember(memberId)

    @Transactional
    fun create(memberId: Long, command: TodoCreateCommand): TodoResult =
        todoAppender.append(memberId, command)

    @Transactional
    fun toggle(memberId: Long, todoId: Long): TodoResult {
        val todo: Todo = todoFinder.getOwned(memberId, todoId)
        return todoAppender.applyToggle(todo)
    }
}
```

## 규칙

- **트랜잭션 경계는 서비스가 소유한다.** 조회 전용은 `@Transactional(readOnly = true)`, 쓰기는 `@Transactional`.

- 구현 레이어(`Finder`/`Appender`/`Sender`)에는 트랜잭션을 걸지 않는다. 경계가 두 곳이 되면 커밋 시점을 알 수 없다.

- 서비스는 리포지토리·엔티티를 직접 만지지 않는다. 구현 레이어만 부른다.

- 반환은 도메인 모델(`Result`)이다. 엔티티나 응답 DTO 를 반환하지 않는다.

- 상세 로직(쿼리 조립, 엔티티 변환, 외부 호출 형식)을 서비스에 쓰지 않는다. 커지면 구현 레이어로 내린다.

- 다른 도메인이 필요하면 그 도메인의 **서비스**를 주입한다.

- 같은 트랜잭션 안에서 외부 시스템 호출(메일·SMS·결제)을 하지 않는다. 실패 시 롤백 범위가 뒤엉킨다 — 커밋 후 이벤트로 분리한다.

- 메서드명은 유스케이스를 나타낸다: `list`, `create`, `toggle`, `reissueToken`.

## 적발 신호

| 신호 | 문제 | 심각도 |
|---|---|---|
| 리포지토리·엔티티 직접 사용 | 구현 레이어 우회 | Critical |
| 트랜잭션 애너테이션 없는 다단계 쓰기 | 부분 반영 위험 | Critical |
| 구현 레이어에도 `@Transactional` | 경계 중복 | Critical |
| 엔티티·응답 DTO 반환 | 레이어 침범 | Critical |
| 트랜잭션 안 외부 시스템 호출 | 롤백 범위 오염·지연 | Critical |
| 조회 전용에 `readOnly` 누락 | 불필요한 더티 체킹 | Important |
| 서비스에 쿼리·변환 상세 | 재사용 불가·비대화 | Important |
| 다른 도메인의 구현 레이어 주입 | 경계 침범 | Critical |

## 체크리스트

- [ ] 트랜잭션 경계가 서비스에만 있는가

- [ ] 흐름 조립 외의 상세 로직이 없는가

- [ ] 반환 타입이 도메인 모델인가

- [ ] 외부 호출이 트랜잭션 밖으로 나갔는가
