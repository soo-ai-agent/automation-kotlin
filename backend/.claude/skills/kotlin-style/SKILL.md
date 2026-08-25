---
name: kotlin-style
description: Kotlin 의 조건·분기·반복 문법 규칙. sealed 타입 상태 표현, else 없는 when, null 좁히기, 람다 분기(?.let·takeIf) 금지, 화살표(->) 최소화, forEach 와 for 의 구분, 빈 컬렉션 접근, 컬렉션 조인, 코루틴 취소 예외를 다룬다. when 분기·sealed·null 처리·코루틴 예외를 작성하거나 리뷰할 때 kotlin-common 과 항상 함께 사용한다. "코틀린 스타일", "when 분기", "sealed", "null 처리" 요청에도 사용할 것.
---

# Kotlin 문법: 조건·분기·반복

**원칙 — 코드에 의도와 로직이 그대로 읽혀야 하고, 처음 보는 사람도 설명 없이 이해할 수 있어야 한다.**

아래 규칙은 전부 이 원칙의 적용이다: 분기를 람다와 `->` 뒤에 숨기지 않고, 케이스 누락을 컴파일러가 잡게 하고, 불가능한 상태를 타입에서 지운다.

규칙에 없는 상황은 이 질문으로 판단한다 — "처음 보는 사람이 이 조건과 흐름을 설명 없이 따라갈 수 있는가?"

**다루는 것** — 분기·반복·상태 표현에서 Kotlin 문법 때문에 달라지는 규칙.

**다루지 않는 것** — 자료형·불변성·람다 체이닝 일반 규칙은 `kotlin-common` 에, 실패 표현(예외 설계)은 `kotlin-error` 에, 서버-클라이언트 계약은 `api-contract` 에, 언어 무관 규칙은 공통 스킬(`.claude/skills/`)에 있다.

이 스킬은 `api-contract`·`frontend-style` 과 목표(유지보수성·정합성·가독성)를 공유한다 — 전문은 `api-contract` 의 "세 스킬이 공유하는 목표" 절.

바쁘면 아래 표만 보면 된다. 근거와 예시는 본문에 있다.

## 핵심 요약

| 상황 | 규칙 |
|---|---|
| 도메인 상태 표현 | `sealed interface` — enum + nullable 조합으로 불가능한 상태를 만들지 않는다 |
| 상태 분기 | `else` 없는 `when`, 식(expression)으로 사용 |
| null 처리 | `?:` 조기 반환으로 좁히기 (`!!` 금지는 `kotlin-common`) |
| 조건 실행 | `?.let`·`takeIf` 같은 람다 분기 금지 — `if () {}` 로 |
| `->` 기호 | 람다 파라미터 이름·콜백 타입 최소화 — `when` 가지는 예외 |
| 실패 표현 | `kotlin-error` 를 따른다 — 도메인 실패를 `Result`·`runCatching` 으로 바꾸지 않는다 |
| 코루틴에서 예외 잡기 | `CancellationException` 은 반드시 다시 던지기 |
| 컬렉션 접근 | `first()` 대신 `firstOrNull()` |

## 1. 상태를 먼저 올바르게 표현한다

분기가 복잡해지는 원인의 절반은 조건문이 아니라 데이터 모양이다.

**도메인 상태는 sealed 타입으로 표현한다.** enum 과 nullable 필드의 조합은 불가능한 상태를 표현 가능하게 만들고,
그 상태를 막느라 쓰는 곳마다 방어 분기가 생긴다.

```kotlin
// ❌ "PAID 인데 paidAt == null" 이 표현 가능 → 쓰는 곳마다 null 확인
data class OrderResult(val status: OrderStatus, val paidAt: Instant?)

// ✅ 불가능한 상태가 타입에서 사라짐
sealed interface OrderResult {
    data class Pending(val id: Long) : OrderResult
    data class Paid(val id: Long, val paidAt: Instant) : OrderResult
}
```

sealed 타입의 자리는 도메인 모델과 같다 — `core/core-<도메인>/.../domain/model/`.
상태에 딸린 값이 없어 단순 열거로 충분하면 기존 enum 규칙(`kotlin-module-layout` 의 `core-enum` 배치)을 그대로 쓴다.
엔티티의 상태 컬럼은 enum + `@Enumerated(STRING)` 그대로다(`kotlin-entity`) — sealed 변환은 구현 레이어가 한다.

**`Pair`·`Triple` 은 함수 경계를 넘기지 않는다.** `result.first` 가 무엇인지는 작성자만 안다.
지역 임시값을 넘어서면 `data class` 로 이름을 붙인다 (rules.md 의 "raw map/tuple 대신 명시적 모델" MUST 의 Kotlin 적용).

## 2. 분기

**sealed 타입 분기에는 `else` 를 쓰지 않는다.** `else` 가 없어야 새 하위 타입이 생겼을 때 처리 누락을 컴파일러가 잡는다.

```kotlin
// ❌ Refunded 가 추가돼도 컴파일 통과 — 조용히 else 로 흘러감
when (order) {
    is Pending -> show(order)
    is Paid -> show(order)
    else -> {}
}

// ✅ Refunded 추가 시 이 지점에서 컴파일 에러
when (order) {
    is Pending -> show(order)
    is Paid -> show(order)
}
```

**`when` 은 값을 반환하는 식으로 쓴다.** 모든 가지가 값을 내야 하므로 빠진 가지가 저절로 드러난다.

**특수 사례는 함수 맨 위에서 끝낸다.** 이 아래는 정상 흐름만 남는다 (guard clause — rules.md SHOULD 와 같은 규칙).

```kotlin
val user = userFinder.findById(id) ?: return null
require(user.isActive) { "inactive user: $id" }
// 여기부터는 정상 흐름
```

**분기에 람다를 쓰지 않는다 — `if () {}` 로 쓴다.** `?.let { }`, `takeIf { }`, `?.let { } ?: run { }` 은 `if` 를 람다로 흉내 낸 것이다.
조건이 어디 있는지 숨기고, 동작마저 다르다.

```kotlin
// ❌ if/else 흉내 — let 블록이 null 을 반환하면 run 까지 "함께" 실행됨
user?.let { greet(it) } ?: run { showLogin() }

// ✅ 조건이 보이고, 동작이 정확함
if (user != null) greet(user) else showLogin()
```

값 선택 한 줄(`x ?: default`)과 조기 반환(`?: return`, `?: throw XxxNotFoundException()`)은 람다가 아니므로 그대로 쓴다.
람다 금지는 제어 흐름에만 적용된다 — 컬렉션 변환 람다는 3번 규칙을 따른다.

**`->` 기호도 최소화한다.** `->` 가 나오는 자리는 셋이고, 각각 다르게 다룬다.

- 파라미터 하나짜리 람다에 이름을 붙이지 않는다. `{ user -> save(user) }` 대신 `it` 이나 메서드 참조 `::save`.

- 콜백 파라미터(함수 타입 `(T) -> R`)는 꼭 필요할 때만 만든다. 결과를 값으로 반환받아 호출부에서 `if () {}` 로 분기하면 흐름이 코드에 보인다.

```kotlin
// ❌ 제어 흐름이 콜백 람다 안으로 숨음
fetchUser(id, onSuccess = { show(it) }, onError = { showRetry() })

// ✅ 흐름이 호출부에 보임
val user: User? = userFinder.findById(id)
if (user != null) show(user) else showRetry()
```

- `when` 가지의 `->` 는 람다가 아니라 문법이다. 케이스 누락을 컴파일러가 잡으려면 `when` 이 필요하므로, `when` 의 `->` 는 최소화 대상이 아니다.

**스마트 캐스트가 안 되면(`var`, 다른 모듈의 프로퍼티) 지역 `val` 에 담고 판단한다.** `?.` 를 줄줄이 다는 것보다 한 번 담는 쪽이 읽기 쉽다.

## 3. 반복

**판단·누적이 들어가는 반복은 `kotlin-common` 대로 `for` 로 풀어서 쓴다.** 판단 없는 단순 변환 한 단계(`map`·`associateBy`)까지가 허용이다.

**`forEach` 는 부수효과 전용이다.** 값을 만들려면 변환 한 단계(`map`)로 하고, 판단이 섞이면 `for` 로 푼다.

**조기 종료가 필요하면 `for` 를 쓴다.** `forEach` 안의 `return` 은 함정이다.

```kotlin
// ❌ 바깥 함수 전체가 종료됨
items.forEach { if (it.isBad) return }

// ✅ 의도가 그대로 보임
for (item in items) {
    if (item.isBad) break
}
```

**빈 컬렉션에서 던지는 접근을 기본값으로 쓰지 않는다.** `first()`·`last()`·인덱스 접근 대신 `firstOrNull()`·`getOrNull()`.
없음을 어떻게 다룰지는 그 자리에서 명시한다(`?: throw`, `?: continue`, `?: 기본값`).

**중첩 루프로 두 컬렉션을 맞추고 있다면 조인이다.** 인덱스(Map)를 먼저 만들고, 짝이 없는 경우를 `for` 안에서 보이게 다룬다.

```kotlin
// ❌ O(n×m), 짝이 없으면 first() 에서 던짐
val rows: List<Row> = orders.map { order -> Row(order, users.first { it.id == order.userId }) }

// ✅ 인덱스는 변환 한 단계로, 판단은 for 안에 보이게
val userById: Map<Long, User> = users.associateBy { it.id }
val rows: MutableList<Row> = mutableListOf()
for (order in orders) {
    // 짝 없는 주문은 결과에서 제외한다
    val user: User = userById[order.userId] ?: continue
    rows.add(Row(order, user))
}
```

## 4. 예외 — 잡는 쪽 규칙

**실패 표현은 `kotlin-error` 가 기준이다.** 도메인 실패는 status·code 를 스스로 가진 `ApiException` 하위 예외로 던진다.
예상 가능한 실패를 `Result`·`runCatching` 반환으로 바꾸지 않는다 — 실패 표현이 두 갈래가 되어 호출부마다 다루는 법이 달라진다.

**코루틴 안에서 광범위하게 잡았다면 취소를 되살린다.** 이 백엔드의 기본은 Spring MVC 라 코루틴이 필수는 아니지만, 코루틴을 쓰는 코드에는 예외 없이 적용한다.
`runCatching` 과 `catch (e: Exception)` 은 `CancellationException` 까지 삼켜, 취소가 안 먹는 코드가 된다.

```kotlin
// ❌ 취소까지 삼킴
val result = runCatching { fetch() }

// ✅ 취소는 통과, 처리할 수 있는 타입만 잡는다 (kotlin-common 의 catch 규칙)
try {
    fetch()
} catch (e: CancellationException) {
    throw e
} catch (e: IOException) {
    // 외부 일시 실패 — 재시도 대상으로 번역한다
    throw ExternalCallFailedException(cause = e)
}
```

## 적발 신호

| 신호 | 문제 | 심각도 |
|---|---|---|
| sealed 타입 분기의 `else` | 새 하위 타입 누락이 조용히 통과 | Critical |
| `forEach` 안의 `return` 으로 조기 종료 의도 | 바깥 함수가 통째로 종료 — 동작 버그 | Critical |
| 코루틴에서 `CancellationException` 을 삼키는 포괄 catch·`runCatching` | 취소 불능 | Critical |
| `Pair`·`Triple` 이 함수 경계를 넘음 | raw tuple 금지(rules.md MUST) 위반 | Critical |
| enum + nullable 조합으로 불가능한 상태가 표현 가능 | 쓰는 곳마다 방어 분기 | Important |
| `?.let { } ?: run { }` 등 람다로 만든 제어 흐름 | 조건 은폐 + let 이 null 반환 시 run 도 실행 | Important |
| 도메인 실패를 `Result`·`runCatching` 으로 반환 | `kotlin-error` 의 예외 규칙과 이원화 | Important |
| 빈 컬렉션에 `first()`·인덱스 접근 | 런타임 예외 | Important |
| 콜백 파라미터로 제어 흐름 전달 | 흐름이 람다 안에 숨음 | Important |
| 문(statement)으로 쓴 `when` + 빠진 가지 | 누락이 컴파일러에 안 잡힘 | Important |

## 체크리스트

- [ ] sealed 분기에 `else` 가 없는가

- [ ] 불가능한 상태가 타입으로 막혀 있는가 (enum + nullable 조합이 없는가)

- [ ] 제어 흐름이 람다(`?.let`·`takeIf`·콜백) 없이 `if`/`when` 으로 보이는가

- [ ] `forEach` 조기 종료가 `for` 로 되어 있는가

- [ ] 코루틴의 포괄 catch 가 취소를 다시 던지는가

- [ ] 실패 표현이 `kotlin-error`(`ApiException` 하위 예외)를 따르는가
