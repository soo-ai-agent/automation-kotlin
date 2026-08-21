---
name: algorithm-implementation
description: 복잡한 알고리즘·계산 로직을 구현할 때의 규칙. 요금·할인·정산 같은 돈 계산, 매칭·배정·스케줄링, 상태 기계, 우선순위·정렬 규칙, 분기가 많은 판정 로직, 수식이 있는 요구사항을 구현하기 전에 반드시 사용할 것. "알고리즘", "계산", "수식", "정책", "규칙 엔진", "복잡한 로직" 같은 요청에도 사용한다. 핵심은 이해를 입출력 표로 먼저 고정하고, 그 표를 테스트로 1:1 변환하는 것이다.
---

# 알고리즘 구현 — 이해를 표로 고정하고, 표를 테스트로

> 어긋남은 코드 실력이 아니라 **해석 차이**에서 온다. 산문 명세는 읽는 쪽마다 다르게 읽힌다. 이 문서는 해석을 실행 가능한 형태로 고정하는 절차다.

## 한눈에

- **구현 전** — 명세에서 입력→출력 표를 만들고, 모호한 점은 가정으로 명시한다

- **구현** — 알고리즘은 순수 함수로 — 엔티티·도메인 모델의 메서드에 두고, 트랜잭션·리포지토리·외부 호출과 분리한다

- **검증** — 표의 행 하나 = 테스트 하나. 경계 케이스를 표에 반드시 포함한다

- **보고** — 가정·복잡도·검증 못 한 것을 결과에 그대로 적는다

---

## 1. 구현 전 — 입출력 표부터 만든다

코드를 쓰기 전에, 명세를 읽고 **구체적 입력 → 기대 출력** 표를 만든다.

명세에 표가 이미 있으면 그대로 쓰고, 없으면 명세에서 도출해 PLAN.md(plan 노드) 또는 결과 보고 첫머리에 남긴다.

```markdown
## 이해한 규칙 (쿠폰 적용)
| 잔액 | 쿠폰 | 최소주문 | 기대 결과 | 근거 |
|---|---|---|---|---|
| 10000 | 3000 | 15000 | 쿠폰 미적용, 10000 | 최소주문 미달 |
| 10000 | 3000 | 5000  | 7000 | 정상 적용 |
| 2000  | 3000 | 0     | 0 (음수 금지) | 결제금액 하한 |
| 0     | -    | -     | 결제 거부 | 잔액 없음 |
```

표를 만들다 규칙이 갈라지는 지점(명세가 답하지 않는 입력)이 나오면, 그것이 **가정**이다.

- 가정은 지어내서 숨기지 않는다. `## 가정` 절에 번호를 붙여 명시하고, 둘 중 보수적인(데이터를 덜 잃고, 돈을 덜 깎는) 쪽을 고른다.

- 예: "쿠폰 금액이 결제액보다 크면? → 가정 1: 0원으로 절사 (음수 결제 금지)"

**표 없이 구현을 시작하지 않는다.** 표가 곧 계약이고, 아래 모든 단계가 표를 참조한다.

## 2. 경계 케이스 — 표에 반드시 넣는 행

명세는 대개 정상 흐름만 말한다. 아래 목록을 훑어 해당되는 행을 표에 추가한다.

| 분류 | 넣을 행 |
|---|---|
| 빈 것 | 빈 목록, 0건, null 대상 |
| 극단 | 최소값(0, 1건), 최대값(상한, 만석), 음수 |
| 돈·수치 | 절사/반올림 방향, 0원, 소수점 (`BigDecimal` — `Double`/`Float` 금지) |
| 중복·순서 | 같은 값 2개, 입력 순서가 결과에 영향 주는가 |
| 시간 | 경계 시각(자정, 시작=종료), 시간대 |
| 동시성 | 같은 대상에 두 요청 (DB 제약·`@Version` 낙관적 락으로 풀 것, 코드 재검사만으로 안 됨) |

## 3. 구현 — 알고리즘은 순수 함수로

계산·판정 로직을 트랜잭션, 리포지토리, 외부 호출에서 떼어 낸다. **입력을 받아 값을 돌려줄 뿐, 아무것도 조회하거나 저장하지 않는 메서드**로 만든다.

이 저장소에서 순수 함수가 사는 자리는 둘이다 — 상태·불변식이 얽힌 규칙은 **엔티티의 행위 메서드**(kotlin-entity), 조회 결과만으로 하는 계산은 **도메인 모델의 메서드**다.

서비스와 구현 레이어에는 조립만 남긴다.

```kotlin
// ❌ 계산이 조회·트랜잭션과 엉킴 — 테스트에 목이 필요하고, 서비스가 리포지토리·엔티티를
//    직접 만진다 (kotlin-domain-service 위반)
@Service
class OrderService(
    private val orderRepository: OrderRepository,
    private val couponRepository: CouponRepository,
) {
    @Transactional
    fun pay(memberId: Long, orderId: Long, couponId: Long?): PaymentResult {
        val order = orderRepository.findByIdAndMemberId(orderId, memberId)
            ?: throw OrderNotFoundException()
        val coupon = couponId?.let { couponRepository.findByIdAndMemberId(it, memberId) }
        var amount = order.total
        if (coupon != null && order.total >= coupon.minOrderAmount && coupon.discountAmount < amount) {
            amount -= coupon.discountAmount   // 규칙이 조회 코드에 파묻힌다
        }
        ...
    }
}
```

```kotlin
// ✅ 규칙은 엔티티의 행위 메서드에 (kotlin-entity·oop-responsibility-design 과 같은 원칙)
// storage/db-core/.../storage/db/core/CouponEntity.kt
@Entity
@Table(name = "coupon")
class CouponEntity(
    @Column(name = "discount_amount", nullable = false)
    val discountAmount: BigDecimal,

    @Column(name = "min_order_amount", nullable = false)
    val minOrderAmount: BigDecimal,
) : BaseEntity() {

    /** 적용 불가면 원금 그대로, 결과는 0 미만이 되지 않는다 (가정 1). */
    fun applyTo(orderAmount: BigDecimal): BigDecimal {
        if (orderAmount < minOrderAmount) {
            return orderAmount
        }
        return (orderAmount - discountAmount).max(BigDecimal.ZERO)
    }
}
```

```kotlin
// core/.../order/domain/service/ — 구현 레이어가 엔티티를 지역변수로 다루고,
// 서비스는 흐름 조립과 트랜잭션 경계만 (kotlin-implement·kotlin-domain-service)
@Component
class OrderPayer(
    private val orderRepository: OrderRepository,
    private val couponRepository: CouponRepository,
) {
    fun pay(memberId: Long, orderId: Long, couponId: Long?): PaymentResult {
        val order: OrderEntity = orderRepository.findByIdAndMemberId(orderId, memberId)
            ?: throw OrderNotFoundException()
        val coupon: CouponEntity? = couponId?.let { couponRepository.findByIdAndMemberId(it, memberId) }
        val amount: BigDecimal = coupon?.applyTo(order.total) ?: order.total
        ...
    }
}

@Service
class OrderService(
    private val orderPayer: OrderPayer,
) {
    @Transactional
    fun pay(memberId: Long, orderId: Long, couponId: Long?): PaymentResult =
        orderPayer.pay(memberId, orderId, couponId)
}
```

규칙:

- 돈·비율은 `BigDecimal`. `Double`/`Float` 로 돈을 계산하지 않는다. 나눗셈은 스케일과 `RoundingMode` 를 명시한다 — 방향은 표의 절사/반올림 행이 정한다.

- 매직 넘버 금지 — `0.1` 이 아니라 `companion object` 의 `val DEFAULT_FEE_RATE = BigDecimal("0.1")` 처럼 이름을 준다.

- 분기가 종류(type) 로 갈리기 시작하면 다형성으로 (oop-responsibility-design 핵심 원칙 3). 단, 종류가 하나뿐일 때 미리 인터페이스를 만들지 않는다 (kotlin-common 2대 원칙).

- 명세에 없는 최적화(캐시, 조기 종료로 인한 순서 변화)를 임의로 넣지 않는다. 성능이 걱정되면 보고에 적고 그대로 둔다 — 정확성 먼저, 최적화는 요청받고.

## 4. 검증 — 표의 행 하나 = 테스트 하나

1절의 표를 그대로 테스트로 옮긴다 — **행 하나가 백틱 이름의 테스트 메서드 하나**다(kotlin-test 의 "한 메서드 = 한 기능"과 같은 말이다).

행을 빼먹지 않았는지 표와 테스트를 나란히 대조한다.

```kotlin
// src/test/kotlin/.../CouponEntityTest.kt — 표의 각 행이 메서드 하나
class CouponEntityTest {

    @Test
    fun `최소주문 금액에 못 미치면 쿠폰을 적용하지 않는다`() {
        val coupon = couponEntity(discountAmount = "3000", minOrderAmount = "15000")

        val amount = coupon.applyTo(BigDecimal("10000"))

        assertThat(amount).isEqualByComparingTo("10000")
    }

    @Test
    fun `최소주문을 넘으면 할인 금액을 뺀다`() {
        val coupon = couponEntity(discountAmount = "3000", minOrderAmount = "5000")

        val amount = coupon.applyTo(BigDecimal("10000"))

        assertThat(amount).isEqualByComparingTo("7000")
    }

    @Test
    fun `할인이 결제액보다 크면 0원으로 절사한다`() {
        val coupon = couponEntity(discountAmount = "3000", minOrderAmount = "0")

        val amount = coupon.applyTo(BigDecimal("2000"))

        assertThat(amount).isEqualByComparingTo("0")
    }

    private fun couponEntity(discountAmount: String, minOrderAmount: String): CouponEntity =
        CouponEntity(discountAmount = BigDecimal(discountAmount), minOrderAmount = BigDecimal(minOrderAmount))
}
```

- `BigDecimal` 단언은 `isEqualByComparingTo` 로 한다. `isEqualTo` 는 스케일까지 비교해 `7000` 과 `7000.00` 을 다르다고 본다.

엔티티 메서드라 목·DB 없이 `./gradlew unitTest` 로 돌고, 돌린 뒤 테스트 실계수를 센다(kotlin-test).

실행하지 못하는 환경이라면, **예시 입력 하나를 골라 단계별 손 계산 트레이스를 보고에 남긴다**:

```
트레이스 (10000, 쿠폰 3000, 최소주문 5000):
  10000 >= 5000 → 적용 대상
  10000 - 3000 = 7000, max(0, 7000) = 7000  ✓ 표와 일치
```

## 5. 보고 — 숨기지 않는다

결과 보고에 반드시 포함한다:

- **가정 목록** — 명세가 답하지 않아 스스로 정한 것 (번호와 선택 이유)

- **복잡도** — 입력이 커질 때의 동작 (예: O(n log n), n = 주문 항목 수)

- **검증 상태** — 표의 몇 행을 테스트로 옮겼고, 실행했는지 / 트레이스로 대신했는지

- **명세와 다르게 한 것** — 없어야 정상이지만, 있다면 반드시 (조용한 변경 금지)

---

## 적발 신호

| 신호 | 왜 문제인가 | 심각도 |
|---|---|---|
| 입출력 예시·테스트 없이 구현된 복잡 분기 | 해석이 맞는지 확인할 방법이 없다 | Critical |
| `Double`/`Float` 로 돈·비율 계산 | 절사 오차가 금액 차이로 누적 | Critical |
| 명세에 없는 동작을 가정 명시 없이 넣음 | 조용한 규칙 변경 — 사용자가 모른다 | Critical |
| 매직 넘버 (이름 없는 상수) | 규칙 변경 시 찾을 수 없다 | Important |
| 경계 케이스(빈 것·극단·중복) 테스트 부재 | 정상 흐름만 맞는 코드 | Important |
| 계산 로직이 트랜잭션·조회와 한 메서드에 엉킴 | 목 없이 테스트 불가 | Important |
| 요청받지 않은 최적화로 결과 순서·값 변화 | 정확성을 성능과 바꿈 | Important |

## 체크리스트

- [ ] 구현 전에 입력→출력 표를 만들었는가 (명세에 있으면 그대로, 없으면 도출해 기록)

- [ ] 표에 경계 케이스 행이 있는가 (§2 목록 대조)

- [ ] 모호한 지점을 가정으로 번호 붙여 명시했는가

- [ ] 계산이 엔티티·도메인 모델의 순수 메서드로 분리됐는가

- [ ] 돈·비율에 `BigDecimal` 을 썼는가

- [ ] 표의 행마다 테스트(또는 손 트레이스)가 있는가

- [ ] 보고에 가정·복잡도·검증 상태를 적었는가
