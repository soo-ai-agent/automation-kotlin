---
name: oop-responsibility-design
description: >-
  책임 주도 설계와 GRASP 패턴. "이 판단·계산을 어디에 둘 것인가"를 정할 때 사용한다. 새 도메인 설계, 도메인 모델링, 책임 할당, 서비스·훅이 비대해질 때, 타입별 when·if 분기가 늘어날 때,
  값을 꺼내 바깥에서 계산하는 코드를 보거나 쓸 때 반드시 사용할 것. "설계", "책임", "어디에 둬야", "도메인 모델", "GRASP", "응집도", "결합도", "다형성", "리팩터링 방향" 같은
  요청에도 사용한다. 백엔드와 프론트엔드 모두에 적용된다 — 계층별 작성 규칙은 백엔드 kotlin-<계층>·프론트 frontend-<레이어> 스킬이,
  이 문서는 그 계층 안에서 무엇을 누구에게 맡길지를 다룬다. 절차적 코드가 객체지향으로 바뀌는 8단계 상세 과정과 영화 예매 코틀린 예제 전문은 reference.md 참고.
---

# 객체 설계 — 책임 주도 설계

> 계층 규칙(어디에 파일을 두나)은 백엔드 kotlin-* · 프론트 frontend-* 스킬에 있다. 이 문서는 **그 계층 안에서 로직을 누구에게 줄 것인가**를 다룬다.
>
> 절차적 코드가 객체지향으로 바뀌는 8단계 상세 과정과 영화 예매 코틀린 예제 전문은 [reference.md](reference.md) 참고.

## 한눈에

- **핵심 질문** — 이 판단·계산을 어느 객체가 해야 하는가

- **원칙** — 데이터를 가진 쪽이 그 데이터로 하는 일도 갖는다

- **순서** — 행동을 먼저 정하고, 그 행동을 할 객체를 고르고, 마지막에 데이터를 붙인다

- **판정 기준** — 응집도는 높게(관련된 것만 한곳에), 결합도는 낮게(서로 덜 알게)

- **언제 쓰나** — 새 도메인 설계, 서비스 비대화, 타입별 분기 증가, getter 남발

- **우선순위** — **core-principles** 3대 원칙(단순함 최우선, 최소 수정·무파괴, 데이터의 흐름과 통제)이 항상 앞선다. 구조는 미리 만들지 않고, 필요해졌을 때 올바른 자리에 만든다.

- **전제** — 처음 보는 사람이 위에서 아래로 읽어 바로 이해하는 코드가 먼저다. 화려한 문법보다 평범하게 쓴 코드가 정답이다.
  판단·반복은 람다로 압축하지 않고 `if`/`for` 로 풀어서 쓴다(kotlin-common).

---

## 1. 나쁜 예 — 데이터와 로직이 갈라진 코드

영화 예매. 서비스가 값을 전부 꺼내 와서 혼자 판단하고 계산한다.

```kotlin
// core/core-reservation/.../reservation/domain/service/ReservationService.kt  ← 하지 말 것
@Service
class ReservationService(
    private val screeningFinder: ScreeningFinder,
    private val reservationAppender: ReservationAppender,
) {
    @Transactional
    fun reserve(screeningId: Long, count: Int): ReservationResult {
        val screening: Screening = screeningFinder.getById(screeningId)
        val movie: Movie = screening.movie

        // 할인 여부를 서비스가 판단한다
        var discounted = false
        if (movie.discountType == DiscountType.PERIOD) {
            if (screening.startedAt.toLocalTime() in movie.startTime..movie.endTime) {
                discounted = true
            }
        }
        if (movie.discountType == DiscountType.SEQUENCE) {
            if (screening.sequence == movie.targetSequence) {
                discounted = true
            }
        }

        // 요금도 서비스가 계산한다
        var fee: BigDecimal = movie.fee
        if (discounted) {
            if (movie.discountKind == DiscountKind.AMOUNT) {
                fee = fee - movie.discountAmount
            }
            if (movie.discountKind == DiscountKind.PERCENT) {
                fee = fee * (BigDecimal.ONE - movie.discountPercent)
            }
        }

        return reservationAppender.append(screeningId, count, fee * count.toBigDecimal())
    }
}
```

**무엇이 문제인가.** `Movie` 는 값을 담고만 있고 아무 판단도 하지 않는다 — 이름만 객체이고 실체는 데이터다. 그래서 이런 일이 일어난다.

| 바뀌는 것 | 고쳐야 하는 곳 |
|---|---|
| 할인 조건 하나 추가 | 서비스의 `if` 더미 + Movie 필드 + 이 값을 쓰는 다른 서비스 전부 |
| `discountPercent` 의 타입 변경 | 이 필드를 꺼내 쓰는 모든 호출부 |
| 요금 계산식 수정 | 계산을 복사해 간 모든 곳 (어디에 있는지 찾아야 한다) |

Movie 의 내부 구조가 밖으로 새어 나갔고, 그 구조를 아는 코드가 사방에 생겼다. **데이터가 바뀌면 그 데이터를 아는 모든 코드가 함께 바뀐다.**

---

## 2. 고치는 법 — 책임을 데이터가 있는 곳으로 옮긴다

값을 꺼내 오는 대신, **"해 달라고 요청"** 한다.

```kotlin
// core/core-reservation/.../reservation/domain/model/Movie.kt — 도메인 모델이 요금 계산을 안다
data class Movie(
    val id: Long,
    val title: String,
    val fee: BigDecimal,
    val discountPolicy: DiscountPolicy,
) {
    /** 이 상영에 적용할 1인 요금. 할인 여부와 계산 방식은 정책이 안다. */
    fun calculateFee(screening: Screening): BigDecimal =
        fee - discountPolicy.calculateDiscount(screening)
}
```

```kotlin
// 서비스는 흐름만 조립한다
@Service
class ReservationService(
    private val screeningFinder: ScreeningFinder,
    private val reservationAppender: ReservationAppender,
) {
    @Transactional
    fun reserve(screeningId: Long, count: Int): ReservationResult {
        val screening: Screening = screeningFinder.getById(screeningId)   // 없으면 예외 — get/find 규약(kotlin-implement)
        val reservation: Reservation = screening.reserve(count)           // ← 조합만 한다
        return reservationAppender.append(reservation)
    }
}
```

서비스는 흐름만 조립하고, 판단과 계산은 그 정보를 가진 객체가 한다. 이제 할인 규칙이 바뀌어도 **정책 객체 하나만** 고치면 된다.

---

## 3. 바보 데이터 객체 vs 똑똑한 객체

클래스로 만들었다고 객체가 되는 것은 아니다. 둘을 가르는 것은 **자율성** — 스스로 판단하느냐, 남이 판단해 주느냐다.

| | 바보 데이터 객체 | 똑똑한 객체 |
|---|---|---|
| 성격 | 수동적. 값을 꺼내 주기만 한다 | 능동적. 스스로 판단하고 상태를 지킨다 |
| 외부에 노출하는 것 | 내부 구조 (필드·getter) | 할 수 있는 일 (메서드) |
| 판단하는 곳 | 바깥 (서비스, 컨트롤러) | 자기 안 |
| 필드가 바뀌면 | 꺼내 쓰던 모든 코드가 함께 바뀐다 | 이 클래스만 바뀐다 |

```kotlin
// ❌ 바보 데이터 객체 — 이름은 TodoEntity 지만 하는 일이 없고, 판단은 전부 바깥에서
if (todo.title != request.title) {
    if (request.title.isBlank()) {
        throw TodoTitleBlankException()
    }
    todo.title = request.title        // 공개 세터 — rules.md MUST 위반이기도 하다
}
```

```kotlin
// ✅ 똑똑한 객체 — 자기 규칙을 자기가 안다 (kotlin-entity 의 행위 메서드)
@Entity
class TodoEntity(title: String) : BaseEntity() {
    @Column(name = "title", nullable = false, length = 200)
    var title: String = title
        protected set

    fun rename(newTitle: String) {
        require(newTitle.isNotBlank()) { "제목은 비어 있을 수 없습니다" }
        title = newTitle
    }
}
```

```kotlin
// 호출부(구현 레이어)는 '무엇을 할지'만 말한다
todo.rename(command.title)
```

차이는 코드 길이가 아니라 **규칙이 사는 곳**이다. 위쪽은 제목 검증 규칙이 호출부마다 복사되고 한 곳을 빼먹으면 빈 제목이 저장된다. 아래쪽은 규칙이 한 곳에 있다.

> 판별법: 그 클래스에서 필드와 getter 를 지웠을 때 아무것도 남지 않으면 데이터다.
>
> 엔티티의 컬럼과 DTO 의 필드 자체는 구조상 공개가 정상이다. 숨기라는 뜻이 아니라, **판단·대입을 바깥에서 하지 말라**는 뜻이다.

---

## 4. 설계 순서 — 행동 → 객체 → 데이터

데이터부터 정하면 "어디에 쓰일지 모르니 일단 다 열어 두자"가 되고, 그게 getter 남발의 출발점이다. 순서를 뒤집는다.

1. **행동 정하기** — 이 기능에 필요한 동작은 무엇인가 (`예매를 만든다`, `요금을 계산한다`)

2. **객체 고르기** — 그 동작을 할 정보를 가장 잘 아는 객체는 누구인가

3. **데이터 붙이기** — 그 동작을 구현하는 데 실제로 필요한 필드만 추가

설계할 때는 표 하나로 정리하면 충분하다 (CRC: 객체 · 책임 · 협력자).

| 객체 | 책임 | 협력자 |
|---|---|---|
| Screening | 예매를 만든다, 상영 시각을 안다 | Movie |
| Movie | 이 상영의 요금을 계산한다 | DiscountPolicy |
| DiscountPolicy | 할인을 적용한다 | DiscountCondition |

**이름은 도메인에서 가져온다.** 코드에 `Screening`·`DiscountPolicy` 가 있으면, "할인 규칙을 고쳐 달라"는 요청을 받았을 때 어느 파일을 열지 바로 안다.

도메인과 코드의 모양이 닮을수록 고칠 곳을 찾기 쉽다.

---

## 5. 책임을 누구에게 줄지 고르는 기준 (GRASP)

### 정보 전문가 — 가장 잘 아는 객체에게

그 일을 하는 데 필요한 정보를 가장 많이 가진 객체가 맡는다. 여기서 "안다"는 필드를 저장한다는 뜻이 아니라 **답할 수 있다**는 뜻이다.

직접 계산하든 협력자에게 물어보든 상관없다.

```kotlin
// 요금 계산은 정가와 할인 정책을 아는 Movie 가 맡는다
movie.calculateFee(screening)                 // ✅
val fee = movie.fee - movie.discountAmount    // ❌ 밖에서 값을 꺼내 계산
```

찾는 요령: 책임을 문장으로 쓰고 **목적어**를 본다. "**상영**을 예매한다" → `screening.reserve()`.

### 창조자 — 만들 자격이 있는 객체에게

새 객체를 누가 만들지 정한다. 아래 중 하나라도 해당하면 그 객체가 만든다.

- 만들어지는 객체를 필드로 갖거나 목록으로 관리한다

- 그 객체를 자주 쓴다

- 생성에 필요한 정보를 가장 많이 갖고 있다

```kotlin
// Screening 은 예매 대상이고 시각·회차 정보를 갖는다 → 예매를 만든다
data class Screening(
    val id: Long,
    val movie: Movie,
    val sequence: Int,
    val startedAt: LocalDateTime,
) {
    fun reserve(count: Int): Reservation {
        val fee: BigDecimal = movie.calculateFee(this)
        return Reservation(screeningId = id, count = count, totalFee = fee * count.toBigDecimal())
    }
}
```

### 낮은 결합도 — 새 의존을 만들지 않는 쪽으로

이미 아는 사이에 일을 맡기면 새 연결이 생기지 않는다.

`Movie` 가 예매를 만들게 하면 Movie→Reservation 의존이 새로 생기지만, `Screening` 은 이미 예매와 관계가 있어 추가 비용이 없다.

### 높은 응집도 — 한 객체에 서로 다른 일을 섞지 않는다

`Screening` 이 예매 생성과 할인 계산을 모두 하면, 둘은 서로 관련 없는 일이라 응집도가 떨어진다. 계산은 `Movie` 로, 할인 규칙은 `DiscountPolicy` 로 나눈다.

**정보 전문가로 후보를 고르고, 응집도·결합도로 최종 결정한다.**

### 다형성 — 타입별 분기를 타입으로 바꾼다

`if (kind == AMOUNT) ... if (kind == PERCENT) ...` 가 보이면 신호다. 분기마다 클래스를 만들고 같은 이름의 메서드를 주면 분기가 사라진다.

```kotlin
// ❌ 새 할인 방식이 생길 때마다 이 함수를 고쳐야 한다 — 그리고 이런 분기가 여러 곳에 생긴다
fun applyDiscount(kind: DiscountKind, fee: BigDecimal, movie: Movie): BigDecimal {
    if (kind == DiscountKind.AMOUNT) {
        return fee - movie.discountAmount
    }
    if (kind == DiscountKind.PERCENT) {
        return fee * (BigDecimal.ONE - movie.discountPercent)
    }
    return fee
}
```

```kotlin
// ✅ 새 방식은 클래스 하나를 더하는 것으로 끝난다
abstract class DiscountPolicy(
    private val conditions: List<DiscountCondition>,
) {
    fun calculateDiscount(screening: Screening): BigDecimal {
        for (condition in conditions) {
            if (condition.isSatisfiedBy(screening)) {
                return getDiscountAmount(screening)
            }
        }
        return BigDecimal.ZERO
    }

    protected abstract fun getDiscountAmount(screening: Screening): BigDecimal
}

class AmountDiscountPolicy(
    private val discountAmount: BigDecimal,
    conditions: List<DiscountCondition>,
) : DiscountPolicy(conditions) {
    override fun getDiscountAmount(screening: Screening): BigDecimal = discountAmount
}

class PercentDiscountPolicy(
    private val percent: BigDecimal,
    conditions: List<DiscountCondition>,
) : DiscountPolicy(conditions) {
    override fun getDiscountAmount(screening: Screening): BigDecimal = screening.fixedFee * percent
}

class NoneDiscountPolicy : DiscountPolicy(emptyList()) {   // 할인 없음도 타입으로 — null 검사가 사라진다
    override fun getDiscountAmount(screening: Screening): BigDecimal = BigDecimal.ZERO
}
```

호출부는 어떤 정책인지 몰라도 된다 — `discountPolicy.calculateDiscount(screening)` 하나면 끝이다.

**전환 시점**: 같은 타입 값으로 갈리는 분기가 서로 다른 메서드·파일 **2곳 이상**에 반복될 때다. **1곳뿐이면 그대로 둔다** — 미리 나누는 것이 더 큰 비용이다.

### 공통 창구 고르기 — 그냥 클래스 vs 추상 클래스 vs 인터페이스

| 상황 | 선택 |
|---|---|
| 그 역할을 맡을 클래스가 하나뿐 | 그냥 클래스 (미리 나누지 않는다) |
| 여러 클래스가 공통 흐름·필드를 같이 쓴다 | 추상 클래스 — 공통 흐름은 부모의 일반 메서드, 다른 부분만 `protected abstract` |
| 같이 쓰는 코드 없이 메서드 약속만 필요 | 인터페이스 |

그 역할을 맡을 클래스가 현재 2개 미만이면 창구를 만들지 않는다. 클래스를 나눌지 판단하는 세 신호는 다음과 같다 (하나라도 걸리면 나눌 후보).

① 바뀌는 이유가 서로 다른 코드가 한 클래스에 있다 ② 함께 쓰이지 않는 메서드·필드가 섞여 있다 ③ 일부 필드를 `null` 로 비워둬야 객체가 만들어진다 (가장 확실한 신호)

닫힌 상태 집합의 표현은 `sealed` 타입이다 — else 없는 `when` 이 빠뜨린 분기를 컴파일 에러로 잡는다(kotlin-style).

### 상속은 역할 대체용 — 아니면 합성

상속은 자식이 부모 자리를 대신 서기 위한 것이지 코드를 물려받기 위한 것이 아니다.

자식 메서드가 부모의 `protected` 필드·내부 구현을 직접 읽거나 대입하면, 그 부분을 별도 클래스로 분리해 프로퍼티로 참조(합성)할 신호다. 실행 중에 종류를 바꿔야 할 때도 같다.

둘 다 아니면 그대로 둔다 — 문제 없는 상속을 합성으로 미리 바꾸는 것도 과설계다.

### 변경 보호 — 바뀔 곳을 인터페이스 뒤에 둔다

자주 바뀔 것(할인 규칙, 외부 API 응답 형식, 정산 방식)은 추상 타입 뒤에 감춘다. 바깥은 인터페이스만 알게 되어, 구현이 바뀌어도 호출부가 그대로다.

판정 기준은 하나다 — **내부 구현을 바꿨을 때 공개된 시그니처가 따라 바뀌면, 그건 인터페이스가 아니라 구현이다.** 모든 필드에 getter 를 연 클래스는 클래스 전체가 구현이다.

---

## 6. 이 프로젝트에서는

계층 규칙과 충돌하지 않는다. 각 계층 안에서 책임을 어떻게 나눌지의 문제다.

### 백엔드 (`backend/`)

| 계층 | 이 문서의 관점에서 |
|---|---|
| 엔티티 (`storage/db-core`) | 상태 전이와 불변식이 사는 곳 — `protected set` + 행위 메서드 (kotlin-entity) |
| 도메인 모델 (`domain/model/`) | 조회 결과로 하는 판단·계산 — 순수 메서드 (algorithm-implementation) |
| 도메인 서비스 (`domain/service/XxxService`) | 흐름 조립과 트랜잭션. 도메인 판단을 여기서 하지 않는다 (kotlin-domain-service) |
| 구현 레이어 (`Finder`·`Appender`) | 재사용 단위와 엔티티↔모델 변환. 규칙 없음 (kotlin-implement) |
| 리포지토리 (`storage/db-core`) | 저장과 조회만. 규칙 없음 (kotlin-repository) |
| 정책 객체 | 자주 바뀌는 규칙은 별도 타입으로 (`DiscountPolicy`) |

**서비스가 길어지면 대개 엔티티나 도메인 모델이 해야 할 일을 대신하고 있다.** 그럴 때 옮긴다.

- 엔티티 행위 메서드는 자기 불변식을 스스로 지킨다 — 불변식 위반은 표준 예외(`require`·`check`)로 던지고,
  도메인 판정(404·409)은 core 가 그것을 받아 `ApiException` 하위 예외로 바꾼다(kotlin-module-layout·kotlin-error).

  서비스에 남는 guard 는 입력 검증뿐이고, 조회 부재의 `?: throw` 는 구현 레이어의 몫이다(kotlin-implement).

- **다형성 전환 뒤에도 DB 의 타입 컬럼은 남는다.** enum(`core-enum`) → 클래스·sealed 복원은 **구현 레이어 한 곳**에만 둔다(kotlin-style).

  성공 기준은 타입 분기 0개가 아니라, 도메인 코드 곳곳에 흩어져 있던 분기가 그 한 곳으로 모이는 것이다. 새 종류 추가 시 고칠 곳: 새 클래스 + 복원 한 줄.

- 종류가 하나뿐일 때 미리 인터페이스를 만드는 것은 core-principles 제1원칙 위반이다.

### 프론트엔드 (`frontend/src/`)

프론트에는 상태를 가진 도메인 클래스가 없다. 서버가 판단의 원본을 갖고, 화면은 그 결과를 받아 그린다.

그래서 "데이터를 가진 쪽이 그 데이터로 하는 일도 갖는다"는 원칙은 **판단을 서비스 레이어 안에 가두는 것**으로 나타난다.

| 레이어 | 이 문서의 관점에서 |
|---|---|
| types·enums | 서버 DTO 모양과 도메인 값 집합. 판단을 여기 두지 않는다 (frontend-api) |
| services | 업무 규칙과 상태코드 번역이 사는 곳 — 백엔드 엔티티에 해당하는 자리 (frontend-service) |
| hooks | 화면 상태와 흐름 조립 — 백엔드 서비스에 해당하는 자리. 업무 판단을 여기서 하지 않는다 (frontend-hooks) |
| screens·components | props 로 받은 것을 그린다. 판단도 계산도 하지 않는다 (frontend-screen) |
| api·lib | 요청과 인프라만. lib 은 도메인 단어를 모른다 (frontend-lib) |

**훅이 길어지면 대개 서비스가 해야 할 판단을 대신하고 있다.** 그럴 때 옮긴다 — 백엔드에서 서비스→엔티티로 옮기는 것과 같은 동작이다.

- **"똑똑한 객체"의 프론트 대응은 결과 타입이다.** 서비스가 불리언이나 `null` 대신 결과 enum 을 돌려주거나 `ServiceError` 를 던지면,
  호출부는 값을 해석하지 않고 받은 결과로 분기만 한다 (2분법 상세는 frontend-service).

- **다형성 전환의 프론트 대응은 lookup 이다.** 클래스를 늘리는 대신 union·enum 을 키로 하는 `Record` 로 옮긴다.

  성공 기준은 백엔드와 같다 — 흩어져 있던 분기가 한 곳으로 모이고, 새 종류 추가 시 고칠 곳이 그 한 곳뿐인 것.
  닫힌 값 집합의 소진 검사는 frontend-style 이 담당한다.

- 레이어별 작성 규칙(파일 위치, 이름, export 모양)은 frontend-common 색인과 각 레이어 스킬에 있다.

---

## 적발 신호

리뷰에서 이 패턴이 보이면 위험 신호다.

### 백엔드

| 신호 | 왜 문제인가 | 심각도 |
|---|---|---|
| 서비스가 엔티티·모델 값을 꺼내 바깥에서 판단·계산 | 데이터 변경이 모든 호출부로 전파 | Critical |
| 엔티티 속성 직접 대입으로 상태 전이 | 규칙을 우회한 변경, 검증 누락 (rules.md MUST) | Critical |
| 타입·종류 값으로 갈리는 분기가 여러 곳에 반복 (1곳뿐이면 참고 코멘트만) | 새 종류마다 기존 코드 수정 | Important |
| 같은 계산식이 두 곳 이상에 복사됨 | 한쪽만 고쳐져 결과가 갈라진다 | Important |
| 쓰이지 않는 getter·프로퍼티를 미리 열어 둠 | 내부 구조 노출, 캡슐화 붕괴 | Important |
| 메서드 없이 필드만 있는 도메인 클래스 (엔티티 컬럼·DTO 필드 자체는 예외) | 바보 데이터 객체 — 판단이 호출부로 흩어진다 | Important |
| 업무 개념의 "없음"을 `null` + 분기로 처리 (조회 부재의 `?: throw` 는 이 저장소 표준 — 지적 금지) | 분기 증식, 의미가 모호해짐 | Important |
| 한 클래스가 서로 무관한 책임을 함께 가짐 | 수정 시 무관한 로직에 영향 | Important |
| 자식이 부모의 `protected` 필드·내부 구현에 기댐 | 상속 남용 — 합성으로 바꿀 신호 | Important |
| 종류가 하나뿐인데 미리 만든 인터페이스·확장 지점 | 쓰지 않는 구조, 과설계 (rules.md MUST) | Critical |
| 도메인에 없는 이름의 클래스(`XxxManager`, `XxxHelper`, `XxxUtil`) | 책임이 불명확해 아무거나 들어온다 | Important |

### 프론트엔드

같은 신호가 함수형 코드에서 나타나는 모양이다. 위 표의 Critical 두 줄이 아래 Critical 두 줄에 대응한다.

| 신호 | 왜 문제인가 | 심각도 |
|---|---|---|
| 훅·컴포넌트가 상태코드(`result.status === 404`)로 직접 판단 | 업무 규칙이 화면으로 흩어진다 — 서버 응답이 바뀌면 화면마다 고쳐야 한다 | Critical |
| 훅·컴포넌트가 받은 DTO·props 객체를 제자리 수정 | 규칙을 우회한 변경, 다른 사용처로 전파 (rules.md MUST — 불변) | Critical |
| 서비스가 결과를 불리언·`null` 로 알림 | 의미가 사라져 호출부마다 해석이 갈린다 (결과 enum vs `ServiceError` 2분법) | Important |
| 컴포넌트가 서버 DTO 를 뜯어 계산·포맷 | 서버 필드가 바뀌면 그 DTO 를 그리는 모든 컴포넌트가 함께 바뀐다 | Important |
| 같은 판단식이 훅·컴포넌트 두 곳 이상에 복사됨 | 한쪽만 고쳐져 화면마다 다르게 동작한다 | Important |
| 닫힌 값 집합을 문자열 리터럴 비교로 분기 | enum + lookup 으로 옮길 신호 (frontend-style 소진 검사) | Important |
| 역할이 이름에 없는 모듈(`utils.ts`, `helpers.ts`)에 도메인 판단이 들어감 | 책임이 불명확해 아무거나 들어온다 | Important |

아래 체크리스트도 프론트에서는 자리를 바꿔 읽는다 — "엔티티"는 `services/`, "서비스"는 `hooks/` 다.

## 심각도

- **Critical** — 변경이 번지는 구조, 계층 붕괴 → 머지 전 수정

- **Important** — 유지보수성, 과설계 → 수정 권장

## 체크리스트

- [ ] 이 판단·계산은 필요한 정보를 가진 객체 안에 있는가

- [ ] 도메인 클래스가 필드만 있는 껍데기가 아닌가 (자기 규칙을 갖고 있는가)

- [ ] 서비스가 흐름 조립만 하고 있는가

- [ ] 상태 전이가 속성 대입이 아니라 행위 메서드 호출인가

- [ ] 타입별 분기 대신 타입 분리로 풀 수 있는가 (단, 분기가 1곳뿐이면 그대로 둔다)

- [ ] 공통 창구 수단이 맞는가 — 같이 쓰는 코드가 있으면 추상 클래스, 약속만이면 인터페이스, 하나뿐이면 그냥 클래스

- [ ] 업무 개념의 "없음"도 타입으로 표현했는가 (조회 부재의 `?: throw` 는 예외)

- [ ] 새 종류 추가가 클래스 추가(+복원 한 줄)만으로 끝나는가

- [ ] 클래스 이름이 도메인 용어인가

- [ ] 지금 쓰지 않는 접근자를 미리 열어 두지 않았는가
