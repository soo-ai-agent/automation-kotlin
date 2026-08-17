---
name: kotlin-domain-service
description: 도메인 서비스 작성과 리뷰 규칙. core/domain 의 Service 클래스, 유스케이스 오케스트레이션, @Transactional 트랜잭션 경계, 구현 레이어 조합을 다룰 때 사용한다. "비즈니스 로직", "서비스 추가", "트랜잭션 경계" 요청에도 사용할 것.
---

# Domain Service

**자리:** `core/core-<도메인>/.../<도메인>/domain/service/XxxService.kt`

## 역할 — 흐름과 트랜잭션 경계만

유스케이스의 **흐름과 트랜잭션 경계**를 담당한다. 상세 구현은 구현 레이어에 맡기고, 서비스는 순서대로 조립한다.

**왜 리포지토리를 직접 부르지 않나.** 서비스에 조회 조건과 변환 코드까지 들어가면, 다음 유스케이스가 같은 조회를 필요로 할 때 복사하게 된다. 조회를 `TodoFinder` 로 한 번 빼 두면 여러 서비스가 같은 것을 쓴다.

그래서 서비스를 읽으면 **무엇을 어떤 순서로 하는지**만 보이고, 어떻게 하는지는 안 보이는 것이 정상이다.

```kotlin
@Service
class TodoService(
    private val todoFinder: TodoFinder,
    private val todoAppender: TodoAppender,
    private val todoUpdater: TodoUpdater,
) {
    @Transactional(readOnly = true)
    fun list(memberId: Long): List<TodoResult> = todoFinder.listByMember(memberId)

    @Transactional
    fun create(memberId: Long, command: TodoCreateCommand): TodoResult =
        todoAppender.append(memberId, command)

    @Transactional
    fun complete(memberId: Long, todoId: Long): TodoResult = todoUpdater.complete(memberId, todoId)
}
```

## 규칙

- **트랜잭션 경계는 서비스가 소유한다.** 조회 전용은 `@Transactional(readOnly = true)`, 쓰기는 `@Transactional`.

- 구현 레이어(`Finder`/`Appender`/`Sender`)에는 트랜잭션을 걸지 않는다. 경계가 두 곳이 되면 커밋 시점을 알 수 없다.

- 서비스는 리포지토리·엔티티를 직접 만지지 않는다. 구현 레이어만 부른다.

- **찾은 것을 서비스가 들고 있다가 다른 구현 레이어에 넘기지 않는다.** 상태를 바꾸는 구현
  레이어는 **식별자를 받아 스스로 찾는다.** 서비스가 중간에 들고 있으면 그 변수의 타입이
  엔티티가 되어(도메인 모델로는 JPA 변경 감지가 걸리지 않는다) 엔티티가 서비스로 새어 나온다.

  ```kotlin
  // X — 엔티티가 서비스까지 올라온다
  val entity: TodoEntity = todoFinder.getEntity(todoId)
  return todoUpdater.rename(entity, command.title)

  // O — 찾기와 바꾸기가 구현 레이어 안에서 끝난다
  return todoUpdater.rename(todoId, command.title)
  ```

- 반환은 도메인 모델(`Result`)이다. 엔티티나 응답 DTO 를 반환하지 않는다.

- 상세 로직(쿼리 조립, 엔티티 변환, 외부 호출 형식)을 서비스에 쓰지 않는다. 커지면 구현 레이어로 내린다.

- 다른 도메인이 필요하면 그 도메인의 **서비스**를 주입한다.

- 같은 트랜잭션 안에서 외부 시스템 호출(메일·SMS·결제)을 하지 않는다. 실패 시 롤백 범위가 뒤엉킨다 — 커밋 후 이벤트로 분리한다.

- 메서드명은 유스케이스를 나타낸다: `list`, `create`, `toggle`, `reissueToken`.

## 도메인끼리는 이벤트로만 말한다

도메인이 다른 도메인의 구현을 부르지 않는다. **사건을 발행하고, 받는 쪽이 알아서 한다.**
"주문이 완료되면 알림을 보낸다"에서 주문 도메인은 알림 수단을 몰라야 한다.

```kotlin
// X — 주문 도메인이 알림 수단을 안다
notificationSender.send(memberId, "주문이 완료되었습니다.")

// O — 사건만 낸다. 누가 받아 무엇을 하는지 모른다
orderEventPublisher.orderCompleted(orderId)
```

**세 가지를 지킨다.**

1. **발행 전용 서비스를 도메인마다 둔다.** 서비스가 `ApplicationEventPublisher.publishEvent` 를
   직접 부르지 않는다 — `OrderEventPublisher` 처럼 그 일만 하는 클래스가 맡는다.
   사건 이름이 도메인 어휘로 드러나고(`orderCompleted`), 테스트가 그 클래스만 가짜로 바꾸면 된다.

2. **사건 타입은 `core-common` 에 둔다.** 발행 도메인에 두면 받는 쪽이 그 도메인을 의존하게 되어
   "도메인을 넘지 않는다"가 깨진다.

3. **받는 쪽(`@EventListener`)은 그 일을 업으로 하는 도메인이다.** 알림이면 알림 도메인이 받는다.
   `support` 모듈은 상위(core)를 참조할 수 없으므로 리스너를 거기 두지 않는다.

**경계를 넘는 처리는 호출 스레드를 막지 않는다(비동기 계약).** 발행 자체(스프링 이벤트)는
동기지만, 받는 쪽의 실제 일(외부 발송 등)이 원래 요청의 응답 시간을 늘리면 안 된다 —
끝단이 이미 비동기(자기 executor)면 그대로 두고, 동기 작업이 무겁게 들어오면 리스너에
`@Async` 를 붙인다. 판정 기준: **이 사건 처리가 실패하거나 느려져도 원래 요청은 멀쩡한가.**

**`@Async` 를 반사적으로 붙이지 않는다.** 받는 쪽 안에 이미 비동기 계약(자기 executor 로 보내는
클라이언트 등)이 있으면 리스너까지 비동기로 만들 이유가 없다 — 스레드만 두 번 갈아탄다.
**이미 비동기인 계약이 있는지 먼저 본다.** 트랜잭션 커밋 후에 받아야 하는 사건이면
`@TransactionalEventListener(phase = AFTER_COMMIT)` 를 쓴다 — 롤백된 주문의 알림이 나가는 것을 막는다.

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
