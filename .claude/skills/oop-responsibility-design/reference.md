# 책임주도 설계 — 절차적 코드가 객체지향으로 바뀌는 8단계 (상세)

> 이 문서는 학습·설명용 상세 자료다. 리뷰·작성에 바로 쓰는 규칙 요약(선택 기준 표,
> 적발 신호, 체크리스트)은 [SKILL.md](SKILL.md) 에 있다.

영화 예매 시스템 하나를 절차적 코드에서 시작해 여덟 번 고쳐 나간다.
각 변화는 **무엇이 문제였고 → 어떻게 바꿨고 → 그래서 뭐가 좋아졌는지** 순서로 읽으면 된다.

| # | 변화 | 다루는 것 |
|---|---|---|
| [0](#0-모든-규칙에-앞서는-전제--코드는-누구나-읽기-쉬워야-한다) | 전제 | 읽기 쉬운 코드, 절차적 vs 객체지향, 설계란 무엇인가 |
| [1](#변화-1-데이터-뭉치--스스로-판단하는-클래스) | 데이터 뭉치 → 스스로 판단하는 클래스 | 책임의 이동, 바보 데이터 객체 |
| [2](#변화-2-여러-클래스를-아는-서비스--도메인-관계대로-숨긴다) | 서비스가 다 안다 → 도메인 관계대로 숨긴다 | 캡슐화 경계 |
| [3](#변화-3-종류-확인-조건문--각-종류가-스스로-일한다-다형성) | 종류 확인 조건문 → 각자 스스로 | 다형성 |
| [4](#변화-4-공통-창구를-무엇으로-만드나--인터페이스-vs-추상-클래스) | 공통 창구를 무엇으로 만드나 | 인터페이스 vs 추상 클래스, 상속 vs 합성 |
| [5](#변화-5-서비스가-전부-통제--서비스에는-흐름만-남긴다) | 서비스가 전부 통제 → 흐름만 | 제어 분산 |
| [6](#변화-6-설계가-정말-좋아졌는지-확장으로-확인한다) | 확장해 보며 검증 | null 대신 클래스, 컴포지트, DIP·LSP·OCP |
| [7](#변화-7-얼마나-아는가가-아니라-얼마나-자주-같이-바뀌는가) | 결합도를 다시 정의 | 변경 관점의 결합도·캡슐화 |
| [8](#변화-8-부탁메시지과-실행메서드을-떼어-놓는다) | 부탁과 실행을 떼어 놓는다 | 동적 바인딩, 의존성 주입, 타입 캡슐화 |
| [끝](#일을-맡길-클래스를-고르는-순서-grasp-상세) | GRASP 상세 | 일을 맡길 클래스 고르는 순서, CRC, 도메인 모델 |

## 0. 모든 규칙에 앞서는 전제 — 코드는 누구나 읽기 쉬워야 한다

이 문서의 모든 내용은 이 전제 위에 서 있다.

- **코드는 처음 보는 사람도 읽고 바로 이해할 수 있어야 한다.** 화려한 문법보다
  단순하고 평범하게 쓴 코드가 정답이다.
- **짧은 코드가 곧 단순한 코드는 아니다.** 람다 한 줄로 압축한 코드보다, 길더라도
  풀어 쓴 조건문·반복문이 더 읽기 쉬울 때가 많다. 기준은 글자 수가 아니라
  "처음 보는 사람이 위에서 아래로 읽으며 흐름을 따라갈 수 있는가"다.
  그래서 판단과 반복은 코드가 길어지더라도 `if`/`for` 로 풀어서 쓴다.
- **설계 기법은 도구일 뿐이다.** 추상화·다형성·패턴은 코드를 읽기 쉽고 고치기 쉽게
  만들 때만 쓸 가치가 있다. 패턴을 넣었는데 오히려 읽기 어려워졌다면 잘못 쓴 것이다.
- **바뀔 일이 없는 곳에 미리 구조를 만들지 않는다.** 지금 필요한 만큼만 쓴다.

먼저 두 가지 방식의 차이를 알아두자.

- **절차적 설계**: 데이터(필드, 테이블)를 먼저 만들고, 그 데이터를 꺼내 쓰는 로직을
  나중에 얹는다. 문제는 데이터가 바뀔 때마다 그 데이터를 꺼내 쓰던 모든 코드를
  같이 고쳐야 한다는 것이다.
- **객체지향 설계**: 순서를 뒤집는다. **"무슨 일을 해달라고 부탁할 것인가"(행동)를
  먼저 정하고 → 그 일을 맡을 클래스를 고르고 → 필드는 마지막에 정한다.**
  이렇게 하면 바깥 코드는 행동에만 기대므로, 안쪽 데이터를 바꿔도 바깥이 깨지지 않는다.

그리고 '설계'라는 말부터 짚고 가자. 설계는 거창한 것이 아니라 **코드를 어디에
배치할지 정하는 일**이다. 같은 기능도 코드를 어디에 두느냐에 따라 고치기 쉬울 수도,
어려울 수도 있다. 설계가 필요한 이유는 하나 — **요구사항이 바뀔 때 코드를 쉽고
안전하게 고치기 위해서**다. 아래 나오는 모든 원칙은 '변경'을 중심에 두고 있다.

**이 문서 전체는 질문 하나로 요약된다: "이 로직을 가장 잘 아는 클래스는 누구인가?"**

완성된 그림을 먼저 보자. 화살표는 전부 "일을 부탁한다(메시지를 보낸다)"는 뜻이다.

```
ReservationService ── screening.reserve(customer, count) ──▶ Screening
  (흐름·트랜잭션만)                                              │
                                     movie.calculateFee(this)   ▼
                                                              Movie
                                                                │
                             discountPolicy.calculateDiscount(screening)
                                                                ▼
                                              DiscountPolicy  ← 추상 클래스 (공통 흐름을 공유)
                                              ├ AmountDiscountPolicy      금액 할인
                                              ├ PercentDiscountPolicy    비율 할인
                                              ├ NoneDiscountPolicy       할인 없음 (null 대신!)
                                              └ OverlappedDiscountPolicy 중복 할인
                                                                │
                                       condition.isSatisfiedBy(screening)
                                                                ▼
                                            DiscountCondition  ← 인터페이스 (약속만 정의)
                                            ├ SequenceCondition  회차로 판단
                                            └ PeriodCondition    시간대로 판단
```

**이 구조는 한 번에 나온 것이 아니다.** 지금부터 절차적 코드에서 출발해 여기까지 온다.

---

## 변화 1. 데이터 뭉치 → 스스로 판단하는 클래스

### 기존 — 데이터는 값을 보여주기만 하고, 판단은 남이 한다

할인 조건 클래스는 필드를 공개해서 값을 보여주기만 하고,
"할인해도 되는가"라는 판단은 전부 서비스가 대신한다.

```kotlin
// ❌ 필드를 전부 공개한다. 이름만 클래스이지, 사실상 테이블의 한 행이다
class DiscountCondition(
    val type: ConditionType,        // 기간 조건인지 회차 조건인지까지 바깥에 공개
    val sequence: Int,
    val dayOfWeek: DayOfWeek,
    val startTime: LocalTime,
    val endTime: LocalTime,
)

// ❌ 서비스가 조건의 "종류가 무엇인지"를 확인하고, 할 일을 대신 결정한다
var discountable = false
for (condition in movie.discountConditions) {
    if (condition.type == ConditionType.PERIOD) {
        discountable = condition.dayOfWeek == screening.whenScreened.dayOfWeek &&
            condition.startTime <= screening.whenScreened.toLocalTime() &&
            condition.endTime >= screening.whenScreened.toLocalTime()
    } else {
        discountable = condition.sequence == screening.sequence
    }
    if (discountable) {
        break
    }
}
```

**절차적 코드를 알아보는 확실한 신호가 있다: 어떤 객체의 종류를 확인하고,
그 객체가 할 일을 다른 코드가 대신 결정하고 있다면 절차적 코드다.**

이 구조가 왜 쉽게 깨지는지 실제 변경으로 확인해 보자.

| 요구사항이 바뀌면 | 기존 구조에서 고쳐야 하는 곳 |
|---|---|
| 조합 조건 추가 (회차 **그리고** 시간대를 모두 만족해야 할인) | enum 에 값 추가 + **서비스의 분기도 같이 수정** |
| `startTime`/`endTime` 두 필드를 "시간 범위" 클래스 하나로 묶는 개선 | 그 필드를 꺼내 쓰던 **서비스에서 컴파일 에러** |

즉 **데이터를 고치면 그 데이터를 쓰는 코드가 반드시 같이 깨진다.** 이렇게 되는
이유는, 이 데이터가 어디서 어떻게 쓰일지 모르는 채로 설계됐기 때문이다. 어디서
쓰일지 모르니 "혹시 몰라서" 모든 필드를 열어둘 수밖에 없다 — 이런 방식을
**추측에 의한 설계**라고 부른다. getter 로 모든 필드를 열어두면 겉보기엔 필드를
숨긴 것 같지만, 실제로는 **클래스 내부를 통째로 공개한 것과 같다.**

### 변화 — 데이터를 쓰는 로직을 데이터가 있는 곳으로 옮긴다

다른 클래스의 값을 꺼내서 판단하는 로직이 있다면, 그 로직을 값을 가진 클래스
안으로 옮긴다. 이것을 **책임의 이동**이라고 부른다. (객체지향에서는 "이 클래스가
맡은 일"을 **책임**이라고 부른다.)

```kotlin
// ✅ 판단 로직이 데이터 곁으로 왔다. 바깥에는 "할인 되나요?"라는 질문 하나만 열어둔다
class DiscountCondition(
    private val type: ConditionType,       // 종류 판단까지 안으로 숨겼다
    private val sequence: Int,
    private val dayOfWeek: DayOfWeek,
    private val startTime: LocalTime,
    private val endTime: LocalTime,
) {
    fun isSatisfiedBy(screening: Screening): Boolean {
        if (type == ConditionType.PERIOD) {
            return isSatisfiedByPeriod(screening)
        }
        return isSatisfiedBySequence(screening)
    }

    private fun isSatisfiedByPeriod(screening: Screening): Boolean {
        val screeningTime: LocalTime = screening.startTime.toLocalTime()
        return screening.startTime.dayOfWeek == dayOfWeek &&
            screeningTime >= startTime &&
            screeningTime <= endTime
    }

    private fun isSatisfiedBySequence(screening: Screening): Boolean {
        return screening.isSequence(sequence)
    }
}
```

**무엇이 달라졌나:**

| 관점 | 기존 | 변화 후 |
|---|---|---|
| getter | 모든 필드 공개 | 전부 삭제, 필드는 `private` |
| 조합 조건 추가 | 서비스까지 수정 | `isSatisfiedBy` 안에서 끝 |
| 시간 범위 클래스 도입 | 서비스 컴파일 에러 | 클래스 내부만 고침, 바깥 영향 0 |

바깥에서 보이는 것은 `isSatisfiedBy` 라는 질문 하나뿐이다. 안쪽 필드를 아무리
바꿔도, 이 질문에 답만 할 수 있으면 바깥 코드는 아무것도 모른다.
**바깥 코드가 데이터가 아니라 행동(질문과 대답)에 기대게 만드는 것** —
이것이 이후 모든 변화에 공통으로 깔린 원리다.

### 바보 데이터 객체 vs 똑똑한 객체

클래스로 만들었다고 전부 '객체'가 아니다. 안에 담긴 로직이 그 인스턴스를 어떤
존재로 만드는지에 따라 갈린다.

- **바보 데이터 객체**: 위의 "기존" `DiscountCondition` 처럼, 값을 바깥에 보여주기만
  하고 판단과 결정은 전부 바깥에 맡기는 수동적인 존재. 이름만 객체이지 본질은
  데이터다.
- **똑똑한 객체**: 위의 "변화 후" `DiscountCondition` 처럼, 자기 상태를 스스로
  관리하고 자기 일을 스스로 판단하는 능동적인 존재. 객체지향에서 그냥 '객체'라고
  하면 이쪽을 말한다.

둘을 가르는 기준은 **자율성**이다 — 자기 원칙에 따라 스스로 판단하고 자기 자신을
통제하는가. 자율적인 객체를 만드는 것이 객체지향 설계의 기본 철학이고, 이 문서의
여덟 가지 변화는 전부 바보 데이터 객체를 똑똑한 객체로 바꿔가는 과정이다.

---

## 변화 2. 여러 클래스를 아는 서비스 → 도메인 관계대로 숨긴다

### 기존 — 서비스가 정책과 조건을 둘 다 안다

변화 1로 판단 로직은 옮겼지만, 서비스는 여전히 `DiscountPolicy`(할인 정책)와
`DiscountCondition`(할인 조건) **두 클래스를 모두** 알고 있다. 아는 클래스가 둘이면,
둘 중 어느 쪽의 공개 메서드가 바뀌어도 서비스를 고쳐야 한다.

### 변화 — 업무에 있는 관계를 코드에도 그대로 만든다

업무(도메인)를 보면 **하나의 할인 정책이 여러 할인 조건을 거느린다.**
이 관계를 코드에도 그대로 만들어서, 조건을 확인하는 일을 정책 안으로 옮긴다.

```kotlin
// ✅ 정책이 조건 목록을 갖고, "조건 확인 → 할인 계산" 흐름을 자기 안에 담았다
class DiscountPolicy(
    private val conditions: List<DiscountCondition>,
) {
    fun calculateDiscount(screening: Screening): Money {
        for (condition in conditions) {
            if (condition.isSatisfiedBy(screening)) {
                return getDiscountAmount(screening)
            }
        }
        return Money.ZERO
    }
}
```

**무엇이 달라졌나:** 서비스가 아는 클래스가 둘에서 하나(`DiscountPolicy`)로 줄었다.
이제 정책이 조건을 바깥에서 보이지 않게 가리는 **울타리** 역할을 한다. 조건이
어떻게 바뀌든 서비스는 영향받지 않는다. 이처럼 **의존하는 클래스 수를 줄이는 가장
좋은 방법은, 업무에 이미 있는 관계를 그대로 코드 구조로 옮기는 것**이다.

---

## 변화 3. 종류 확인 조건문 → 각 종류가 스스로 일한다 (다형성)

### 기존 — 정책 종류가 늘 때마다 조건문이 자란다

금액 할인과 비율 할인은 "할인 금액을 계산한다"는 목적은 같고 계산 방법만 다르다.
이 둘을 한 클래스에 넣으면 종류를 확인하는 분기가 남는다.

```kotlin
// ❌ 새 정책(중복 할인 등)이 생기면 이 조건문을 반드시 고쳐야 한다
fun getDiscountAmount(screening: Screening): Money {
    if (policyType == PolicyType.AMOUNT) {
        return discountAmount
    }
    return screening.fixedFee.times(percent)
}
```

문제는 두 가지다.

- 서로 관계없는 계산 로직 두 개가 한 클래스에 섞여 있다. 금액 계산과 비율 계산은
  쓰는 필드도 다르고 공유하는 코드도 없다. 이렇게 **상관없는 일이 한 클래스에 섞여
  있는 상태**를 "응집도가 낮다"고 한다. 응집도가 낮으면 고칠 곳을 찾기 어렵고,
  한쪽을 고치다 상관없는 다른 쪽을 건드려 버그를 내기 쉽다.
- 새 종류를 추가하려면 이미 잘 돌아가는 기존 코드를 열어서 수정해야 한다.
  이렇게 **한 클래스가 바뀔 때 다른 클래스도 따라 바뀌는 정도**를 "결합도"라고
  하는데, 지금은 결합도가 높은 상태다.

### 변화 — 목적이 같고 방법만 다르면, 종류별로 클래스를 나누고 부탁은 하나로 통일한다

```kotlin
// ✅ 계산 방법마다 독립된 클래스. 부르는 쪽은 calculateDiscount 하나만 알면 된다
class AmountDiscountPolicy(
    private val discountAmount: Money,
    conditions: List<DiscountCondition>,
) : DiscountPolicy(conditions) {
    override fun getDiscountAmount(screening: Screening): Money {
        return discountAmount
    }
}

class PercentDiscountPolicy(
    private val percent: Double,
    conditions: List<DiscountCondition>,
) : DiscountPolicy(conditions) {
    override fun getDiscountAmount(screening: Screening): Money {
        return screening.fixedFee.times(percent)
    }
}
```

**무엇이 달라졌나:** 부르는 쪽(`Movie`)은 "할인 금액 계산해줘"(`calculateDiscount`)라는
**부탁 하나만** 보낸다. 그 부탁을 받았을 때 실제로 어떤 코드가 실행될지는, 그 순간
그 자리에 있는 객체가 스스로 정한다. 이렇게 실행할 메서드가 컴파일할 때가 아니라
실행 중에 정해지는 것을 **동적 바인딩**이라고 부른다. **같은 부탁을 받아도 객체
종류에 따라 다르게 동작하는 것 — 이것이 다형성이고, 동적 바인딩이 그것을 가능하게
하는 장치다.** 부탁하는 쪽은 상대가 금액 할인인지 비율 할인인지 알 필요가 없고,
새 정책은 그 부탁을 처리할 수 있는 클래스를 하나 더 만들어 끼워 넣기만 하면 된다.

다만 아직 한 가지가 남았다. `Movie` 가 두 구체 클래스를 직접 필드로 들고 조건문으로
고른다면 달라진 게 없다. **바뀌는 종류들 앞에 잘 안 바뀌는 공통 창구를 하나 세우고,
`Movie` 는 그 창구만 알게** 해야 한다. 그 창구를 무엇으로 만들지가 다음 변화다.

---

## 변화 4. 공통 창구를 무엇으로 만드나 — 인터페이스 vs 추상 클래스

여러 클래스가 같은 자리를 대신할 수 있게 해주는 공통 창구를 **역할**이라고 부른다.
역할을 만드는 수단은 세 가지이고, 고르는 기준은 딱 하나다:
**"같이 쓰는 코드가 있는가?"**

| 상황 | 선택 | 이 예제에서 |
|---|---|---|
| 그 역할을 맡을 클래스가 **하나뿐** | 그냥 클래스 (미리 나누지 않는다) | `Screening`, `Movie` |
| 여러 클래스가 **공통 흐름·필드를 같이 쓴다** | **추상 클래스** | `DiscountPolicy` |
| 같이 쓰는 코드 없이 **약속(메서드 모양)만** 필요 | **인터페이스** | `DiscountCondition` |

### 추상 클래스 — 공통 흐름은 부모가 갖고, 다른 부분만 자식이 채운다

모든 할인 정책은 "조건 중 하나라도 맞으면 할인한다"는 **흐름이 똑같고**,
할인 금액을 **계산하는 방법만 다르다.** 그래서 같은 부분은 부모의 일반 메서드로
두고, 다른 부분만 `abstract` 로 비워 두어 자식이 채우게 한다.

```kotlin
abstract class DiscountPolicy(
    private val conditions: List<DiscountCondition>,
) {
    // 바뀌지 않는 공통 흐름 — 부모가 갖는다
    fun calculateDiscount(screening: Screening): Money {
        for (condition in conditions) {
            if (condition.isSatisfiedBy(screening)) {
                return getDiscountAmount(screening)
            }
        }
        return Money.ZERO
    }

    // 정책마다 다른 부분 — 자식이 각자 채운다
    protected abstract fun getDiscountAmount(screening: Screening): Money
}
```

### 인터페이스 — 같이 쓰는 코드 없이, 지켜야 할 약속만 정한다

회차 조건과 기간 조건은 판단 방법도 필드도 전혀 겹치지 않는다. 같이 쓸 코드가
없으니 **"이 질문에 답할 수 있어야 한다"는 약속만** 정한다. 변화 1의
`DiscountCondition` 은 아직 `type` 필드로 안에서 분기하고 있었는데, 이것도
종류별 클래스로 마저 나눈다.

```kotlin
interface DiscountCondition {
    fun isSatisfiedBy(screening: Screening): Boolean
}

class SequenceCondition(
    private val sequence: Int,
) : DiscountCondition {
    override fun isSatisfiedBy(screening: Screening): Boolean {
        return screening.isSequence(sequence)
    }
}

class PeriodCondition(
    private val dayOfWeek: DayOfWeek,
    private val startTime: LocalTime,
    private val endTime: LocalTime,
) : DiscountCondition {
    override fun isSatisfiedBy(screening: Screening): Boolean {
        val screeningTime: LocalTime = screening.startTime.toLocalTime()
        return screening.startTime.dayOfWeek == dayOfWeek &&
            screeningTime >= startTime &&
            screeningTime <= endTime
    }
}
```

**무엇이 달라졌나:** 변화 1에서는 클래스가 하나뿐이라 회차 조건도 쓰지 않는 시간
필드를 억지로 들고 있었다. 종류별로 나눈 뒤에는 **각 클래스가 자기 판단에 필요한
필드만 갖는다.** 한 클래스가 한 가지 일에만 집중하게 됐다.

클래스를 나눌지 판단할 때 쓸 수 있는 기준은 세 가지다. 하나라도 걸리면 나눌 신호다.

1. **바뀌는 이유가 다른 코드**는 서로 다른 클래스로 나눈다.
   (회차 판단 규칙과 시간대 판단 규칙은 서로 다른 이유로 바뀐다.)
2. **함께 사용되는 메서드와 필드**끼리 묶는다.
   (`sequence` 는 회차 판단에서만, 시간 필드들은 기간 판단에서만 쓰인다.)
3. **함께 초기화되는 필드**끼리 묶는다.
   (회차 조건을 만들 때 시간 필드는 채울 값이 없어 비워둬야 했다 — 나뉘어야 한다는 신호.)

### 주의 — 상속은 "코드를 물려받으려고" 쓰는 것이 아니다

상속은 자식이 부모의 자리를 대신할 수 있게 하려고 쓰는 것이다. `Movie` 자체를
`AmountDiscountMovie`/`PercentDiscountMovie` 로 상속해서 나누는 설계도 있지만,
두 가지 문제가 있다.

```kotlin
// ❌ 자식이 부모의 protected 필드를 직접 꺼내 쓴다 — 부모의 내부에 손을 넣은 것이다
class PercentDiscountMovie(/* ... */) : Movie(/* ... */) {
    override fun calculateDiscount(): Money {
        return fee.times(percent)     // 부모의 protected fee 에 기대고 있다
    }
}
```

- 부모의 내부 필드가 바뀌면 자식이 깨진다. 부모 입장에서는 숨겼다고 생각한 내부를
  자식이 들여다보고 있는 셈이다.
- 영화와 할인 방식의 관계가 코드를 컴파일하는 순간 굳어 버린다. 실행 중에
  "이 영화를 금액 할인에서 비율 할인으로 바꾸자"를 할 수 없고, 객체를 새로 만들어
  필드를 옮겨 담아야 한다.

그래서 할인 정책을 별도 클래스로 분리하고 `Movie` 가 **필드로 들고 있게** 한다 —
상속 대신 **합성**(다른 객체를 필드로 갖고 일을 맡기는 방식)이다. 합성이면 필드에
새 정책 객체를 넣어주는 것만으로 실행 중에도 정책이 바뀐다.
**자식이 부모의 내부 구현에 기대기 시작하면, 합성으로 바꾸라는 신호다.**

---

## 변화 5. 서비스가 전부 통제 → 서비스에는 흐름만 남긴다

### 기존 — 서비스가 모든 단계를 직접 수행한다

절차적 설계에서 서비스는 조회 → 할인 판단 → 요금 계산 → 저장까지 전부 직접 했다.
이렇게 실행 순서에 대한 통제가 한 클래스에 몰리는 방식을 **중앙집중식 제어
스타일**이라고 부른다. 모든 일이 한 곳에 모이면 그 클래스는 모든 데이터의 내부를
알아야 하고, 어떤 변경이든 결국 그 클래스를 고치게 된다.

### 변화 — 판단은 각 도메인 클래스로, 서비스에는 순서와 트랜잭션만

```kotlin
// ✅ 상영 — "상영을 예매한다"의 목적어. 예매에 필요한 정보를 가장 잘 아는 클래스다
class Screening(
    private val movie: Movie,
    private val sequence: Int,
    private val whenScreened: LocalDateTime,
) {
    fun reserve(customer: Customer, audienceCount: Int): Reservation {
        val fee: Money = movie.calculateFee(this).times(audienceCount)
        return Reservation(customer, this, audienceCount, fee)
    }

    fun isSequence(sequence: Int): Boolean {
        return this.sequence == sequence
    }

    val startTime: LocalDateTime get() = whenScreened
    val fixedFee: Money get() = movie.fee
}

// ✅ 영화 — 정가와 할인 정책을 아는, 요금 계산을 가장 잘하는 클래스
class Movie(
    private val title: String,
    val fee: Money,
    private val discountPolicy: DiscountPolicy,
) {
    fun calculateFee(screening: Screening): Money {
        return fee - discountPolicy.calculateDiscount(screening)
    }
}

// ✅ 서비스 — 판단이 한 줄도 없다. 순서와 트랜잭션 경계만 갖는다
@Service
class ReservationService(
    private val customerFinder: CustomerFinder,
    private val screeningFinder: ScreeningFinder,
    private val reservationAppender: ReservationAppender,
) {
    @Transactional
    fun reserveScreening(customerId: Long, screeningId: Long, audienceCount: Int): Reservation {
        val customer: Customer = customerFinder.getById(customerId)
        val screening: Screening = screeningFinder.getById(screeningId)
        val reservation: Reservation = screening.reserve(customer, audienceCount)
        reservationAppender.append(reservation)
        return reservation
    }
}
```

**무엇이 달라졌나:** 일이 한 곳에 몰려 있지 않고 여러 클래스로 **나뉘어** 있다.
각 클래스는 자기가 못 하는 일을 그 일을 더 잘하는 클래스에게 부탁한다
(상영 → 영화 → 정책 → 조건). 어떤 클래스에 일을 맡길지 애매하면 **요구사항을
문장으로 써보라. "상영을 예매한다"의 목적어(상영)를 주어로 바꾸면
`screening.reserve(...)` 가 된다.** 목적어가 곧 일을 맡을 클래스의 힌트다.

어떤 구체 정책과 일할지는 코드에 박아두지 않고, **객체를 만드는 시점에 바깥에서
넣어준다(의존성 주입).** 도메인 예시 "한산"을 그대로 조립하면:

```kotlin
val hansan = Movie(
    title = "한산",
    fee = Money.wons(10_000),
    discountPolicy = AmountDiscountPolicy(
        discountAmount = Money.wons(1_000),
        conditions = listOf(
            SequenceCondition(sequence = 1),                                             // 조조
            SequenceCondition(sequence = 10),
            PeriodCondition(DayOfWeek.MONDAY, LocalTime.of(10, 0), LocalTime.of(12, 0)),
            PeriodCondition(DayOfWeek.WEDNESDAY, LocalTime.of(18, 0), LocalTime.of(21, 0)),
        ),
    ),
)
```

예시에 계속 나온 `Money` 는 금액을 나타내는 작은 불변 클래스다. `Long` 같은 원시
타입 대신 "금액"이라는 업무 개념을 타입으로 드러내고, 값을 바꿀 때마다 새 객체를
만든다.

```kotlin
data class Money(private val amount: BigDecimal) {
    operator fun plus(other: Money): Money = Money(amount + other.amount)
    operator fun minus(other: Money): Money = Money(amount - other.amount)
    fun times(multiplier: Double): Money = Money(amount * BigDecimal.valueOf(multiplier))

    companion object {
        val ZERO: Money = wons(0)
        fun wons(amount: Long): Money = Money(BigDecimal.valueOf(amount))
    }
}
```

---

## 변화 6. 설계가 정말 좋아졌는지 확장으로 확인한다

좋은 설계인지 확인하는 방법은 하나뿐이다 — 요구사항을 실제로 추가해 보고,
**기존 코드를 몇 군데나 고치는지 세어본다.**

### 확인 1. 할인 없는 영화 — `null` 이 아니라 클래스로 표현한다

```kotlin
// ❌ 기존 방식 — 정책 필드를 null 허용으로 만든다. 문제가 두 가지 생긴다
class Movie(
    private val discountPolicy: DiscountPolicy?,   // "할인 없음"인지 "아직 설정 안 됨"인지 알 수 없다
) {
    fun calculateFee(screening: Screening): Money {
        if (discountPolicy == null) {              // 정책을 쓰는 모든 곳에 null 확인이 강제된다
            return fee
        }
        return fee - discountPolicy.calculateDiscount(screening)
    }
}
```

```kotlin
// ✅ 변화 — "할인 없음"도 하나의 정책이다. 예외 상황도 똑같은 협력에 참여시킨다
class NoneDiscountPolicy : DiscountPolicy(emptyList()) {
    override fun getDiscountAmount(screening: Screening): Money {
        return Money.ZERO
    }
}
```

`Movie` 는 여전히 아무 조건 없이 같은 부탁을 보낸다. null 확인 분기가 사라지고
실행 흐름이 한 갈래로 돌아왔다. 기존 코드 수정: **0곳.**

### 확인 2. 중복 할인 — 협력 상대의 "개수"까지 숨긴다

하나의 영화에 여러 할인 정책을 함께 걸 수 있게 되었다고 하자.

```kotlin
// ❌ 절차적 방식이었다면 — 서비스의 계산 로직에 리스트와 루프를 밀어 넣게 된다.
//    "중복 할인"이라는 업무 용어가 코드 어디에도 이름으로 존재하지 않아서,
//    알고리즘을 읽고 나서 머릿속으로 "아, 이게 중복 할인이구나"를 재구성해야 한다
```

여기서 바뀌는 것은 **함께 일할 정책의 개수**다. 여러 정책을 묶은 클래스가
`DiscountPolicy` 자리에 대신 들어가게 만들면, `Movie` 는 정책이 몇 개인지 모른 채
지금까지처럼 부탁 하나만 보내면 된다.

```kotlin
// ✅ 중복 할인은 항상 하위 정책들에게 계산을 맡겨야 하므로, 조건 검사를 무조건 통과시킨다
class AlwaysSatisfiedCondition : DiscountCondition {
    override fun isSatisfiedBy(screening: Screening): Boolean = true
}

class OverlappedDiscountPolicy(
    private val policies: List<DiscountPolicy>,
) : DiscountPolicy(listOf(AlwaysSatisfiedCondition())) {

    override fun getDiscountAmount(screening: Screening): Money {
        var total: Money = Money.ZERO
        for (policy in policies) {
            total = total + policy.calculateDiscount(screening)
        }
        return total
    }
}
```

이렇게 여러 객체를 묶은 클래스가 낱개 객체와 같은 자리에 설 수 있게 만드는 방식을
**컴포지트 패턴**이라고 부른다. "중복 할인"이라는 **업무 용어가 클래스 이름으로
그대로 드러난다.** 요구사항이 바뀌면 열어볼 파일이 이름만으로 예측된다.
기존 코드 수정: **0곳.**

### 이 구조를 받치는 세 가지 원칙

- **의존성 역전 (DIP)**: 부르는 쪽(`Movie`)도 불리는 쪽(`AmountDiscountPolicy`)도
  구체 클래스가 아니라 공통 창구(`DiscountPolicy`)에 기댄다. 변경이 이 창구에서
  멈추고 바깥으로 번지지 않는다.
- **리스코프 치환 (LSP)**: 모든 자식 정책은 `Movie` 입장에서 `DiscountPolicy` 자리를
  아무 문제 없이 대신할 수 있다. 대신할 수 없다면 그 상속은 잘못 만든 것이다.
- **개방-폐쇄 (OCP)**: 새 정책·조건은 클래스를 추가하는 방법으로만 들어온다.
  확장할 때는 열려 있고, 기존 코드 수정은 막혀 있다.

확장하는 방법이 "상속받거나 구현하거나" 하나뿐이라는 것도 큰 장점이다 —
**구조를 한 번 파악하면, 새 기능이 어디에 들어갈지 누구나 예측할 수 있다.**

---

## 변화 7. "얼마나 아는가"가 아니라 "얼마나 자주 같이 바뀌는가"

마지막으로 개념 하나를 바로잡자. 절차적 `DiscountPolicy` 와 개선된
`DiscountPolicy` 는 겉으로 드러내는 것이 같다 — 클래스 이름과 메서드 모양.
그런데 왜 한쪽만 좋은 설계인가?

**결합도는 상대를 "얼마나 아는가"가 아니라, 상대가 바뀔 때 "얼마나 자주 나도 같이
바뀌는가"로 재야 한다.** 비슷한 말인 의존성과는 이렇게 구분한다 — 의존성은 같이
바뀔 **가능성이 있는가**(있다/없다)이고, 결합도는 실제로 **얼마나 자주** 같이
바뀌는가(높다/낮다)다.

- 기존: getter 가 필드의 이름과 타입을 그대로 드러낸다. 필드 타입을 바꾸면 getter
  모양이 바뀌고, 그걸 쓰던 코드까지 줄줄이 고쳐야 한다. **getter 는 공개 창구처럼
  보이지만, 실제로는 내부를 그대로 비추는 유리창이다.**
- 변화 후: `Movie` 는 `calculateDiscount(screening)` 이라는 메서드 모양 하나에만
  기댄다. 내부의 조건 목록을 `List` 에서 `Set` 으로 바꾸든, 비율 필드의 타입을
  바꾸든, 메서드 바깥으로는 아무것도 새어 나가지 않는다.

여기서 캡슐화의 진짜 의미가 나온다. **캡슐화란 "자주 바뀌는 부분을 잘 안 바뀌는
창구 뒤에 숨기는 것"이다.** 필드를 `private` 으로 만드는 것 자체가 목적이 아니라,
바뀌어도 바깥이 모르게 만드는 것이 목적이다.

객체지향 설계가 처음부터 이것에 성공하는 이유는 단순하다. **부탁(메시지)을 먼저
정하기 때문이다.** 협력을 설계하는 시점에는 내부 필드가 아직 없다. 없는 것에는
기댈 수 없으니, 바깥 코드는 자연스럽게 행동에만 기대게 된다.

---

## 변화 8. 부탁(메시지)과 실행(메서드)을 떼어 놓는다

변화 3~4에서 "부탁을 하나로 통일한다"고 했는데, 그 말이 실제로 무엇을 떼어 놓는
것인지 여기서 정리한다.

- **부탁(메시지)**: 부르는 쪽이 "이걸 해 달라"고 보내는 요청. **부르는 쪽이 정한다.**
- **실행(메서드)**: 받은 쪽이 그 부탁을 처리하려고 실제로 돌리는 코드.
  **받는 쪽이 정한다.**

`DiscountPolicy` 는 `isSatisfiedBy(screening)` 이라는 **부탁 하나만** 보낸다.
그 부탁을 받은 것이 `SequenceCondition` 이면 회차를 비교하는 코드가 돌고,
`PeriodCondition` 이면 요일과 시간대를 비교하는 코드가 돈다. **어느 코드가 돌지는
컴파일하는 시점이 아니라 실행하는 시점에 정해진다** — 이것을 동적 바인딩이라고
부른다. 다형성은 이 "부탁과 실행의 분리 + 실행 시점 결정"으로 굴러간다.

### 부탁이 곧 협력 상대를 꽂는 자리가 된다

`DiscountPolicy` 는 상대의 **종류를 가정하지 않고 부탁만 가정한다.** 그래서 그
부탁에 답할 수 있는 것이면 무엇이든 협력에 참여할 수 있다. 부탁이 **협력 상대를
꽂을 수 있는 자리**가 되는 것이다.

코틀린 같은 정적 타입 언어에서는 부탁만 덩그러니 떼어 둘 수 없어서 이름을 붙여야
하는데, 그것이 인터페이스다. `DiscountCondition` 인터페이스가 곧 그 꽂는 자리다.
새 조건을 만들고 싶으면 이 인터페이스를 구현하기만 하면 되고, `DiscountPolicy` 는
**한 줄도 고치지 않는다.**

### 컴파일할 때 기대는 것과 실행할 때 기대는 것이 다르다

여기서 걸림돌이 하나 생긴다.

- **컴파일 시점**: `DiscountPolicy` 는 `DiscountCondition`(인터페이스)에 기댄다.
- **실행 시점**: 실제로는 `PeriodCondition` 객체에게 부탁을 보내야 한다.

이 둘이 다르므로, 누군가 실행 시점에 진짜 객체를 만들어 그 자리에 **넣어 줘야**
한다. 바깥에서 만들어 넣어 주는 이 방식이 **의존성 주입**이다. 수단은 생성자다.

```kotlin
abstract class DiscountPolicy(
    private val conditions: List<DiscountCondition>,   // 무엇이 올지는 바깥이 정한다
) { /* ... */ }

// 만드는 쪽에서 실제 종류를 꽂아 넣는다
val policy: DiscountPolicy = AmountDiscountPolicy(
    discountAmount = Money.of(1_000),
    conditions = listOf(
        PeriodCondition(DayOfWeek.MONDAY, LocalTime.of(10, 0), LocalTime.of(12, 0)),
        SequenceCondition(sequence = 1),
    ),
)
```

```kotlin
// ❌ 안에서 직접 만들면 종류가 컴파일 시점에 굳는다 — 다형성을 만든 의미가 없어진다
abstract class DiscountPolicy {
    private val conditions = listOf(PeriodCondition(/* ... */))
}
```

**이 프로젝트에서는 스프링이 이 일을 대신한다.** 컨트롤러·도메인 서비스·구현
레이어에서 "생성자 주입만 쓰고 `@Autowired` 필드 주입을 금지"하는 규칙이 바로 이
이유다. 필드 주입은 **바깥에서 바꿔 끼울 자리를 없애 버린다.**

### 무엇이 인터페이스이고 무엇이 구현인가 — 판정 기준

설계에서 **추상화는 잘 안 바뀌는 부분**, **구현은 자주 바뀌는 부분**을 가리킨다.
결합도를 낮추려면 자주 바뀌는 쪽이 아니라 잘 안 바뀌는 쪽에 기대야 한다.
그런데 "이게 공개 창구인가 내부 구현인가"는 `public` 인지 아닌지로 갈리지 않는다.
판정 기준은 하나다.

> **내부 구현을 바꿨을 때 공개된 모양(시그니처)이 따라 바뀌면, 그것은 인터페이스가
> 아니라 구현이다.**

| | 내부를 바꾸면 | 판정 |
|---|---|---|
| `getPercent(): Double` | 필드 타입을 `Double` → `Rate` 로 바꾸면 `getPercent(): Rate` 로 따라 바뀐다 | **구현** |
| `calculateDiscount(screening): Money` | 조건 목록을 `List` → `Set` 으로, 비율을 `Double` → `Rate` 로 바꿔도 그대로다 | **인터페이스** |

그래서 모든 필드에 getter 를 열어 둔 클래스는 **클래스 전체가 구현**이다. `private`
필드와 `public` getter 로 감싼 모양새만 캡슐화이지, 실제로는 내부를 그대로 비추고
있다.

### 캡슐화는 한 층이 아니다

캡슐화는 "자주 바뀌는 것을 잘 안 바뀌는 창구 뒤에 숨기는 것"이다(변화 7). 그러면
**무엇을 숨기느냐**에 따라 층이 나뉜다.

| 숨기는 것 | 이름 | 수단 | 실패하면 |
|---|---|---|---|
| 필드의 이름·타입·구조 | 데이터 캡슐화 | 부탁을 먼저 정하고 필드는 마지막에 | 필드를 바꿀 때 바깥이 따라 바뀐다 |
| 협력 상대의 **종류** | **타입 캡슐화** | 역할(추상 클래스·인터페이스) + 주입 | 종류가 늘 때마다 바깥 조건문을 고친다 |
| 협력 상대의 **개수** | — | 여러 개를 묶은 클래스를 같은 자리에 (컴포지트, 변화 6) | 개수가 바뀔 때 바깥이 따라 바뀐다 |

객체지향에서 더 중요한 쪽은 **타입 캡슐화**다. 변화 6에서 본 세 원칙은 사실 타입
캡슐화를 떠받치는 뼈대다.

- **DIP** — 부르는 쪽도 불리는 쪽도 역할에 기대게 배치한다 → **종류를 감출 자리**를 만든다.
- **LSP** — 자식이 부모 자리를 문제없이 대신할 수 있어야 한다 → 그 자리에 **바꿔 끼울 수** 있다.
- **OCP** — 그 결과 새 종류가 **클래스 추가만으로** 들어온다.

### 다만, 설계는 트레이드오프다

상속으로 나눈 설계도 응집도·결합도·캡슐화를 대체로 만족한다. **대부분의 경우
거기서 멈춰도 된다.** 합성으로 옮겨야 하는 신호는 둘뿐이다(변화 4).

1. 자식이 부모의 `protected` 필드·내부 구현에 직접 손을 댄다 (캡슐화가 깨진다).
2. 실행 중에 종류를 바꿔야 한다 (컴파일 시점에 굳는 것이 문제가 된다).

둘 다 아니라면 합성으로 바꾸는 것은 **바뀔 일 없는 곳에 구조를 미리 만드는 일**이다.
변하지 않는 것에 복잡성을 더하지 않는다.

---

## 일을 맡길 클래스를 고르는 순서 (GRASP 상세)

GRASP 는 "어떤 클래스에 일을 맡길까"를 고를 때 쓰는 판단 기준 모음이다.

1. **기능을 "맡길 일"로 바꾼다.** "상영을 예매한다" → 예매를 만들어낼 일.
2. **그 일에 필요한 정보를 가장 잘 아는 클래스를 찾는다.** 문장의 목적어가 힌트다.
   여기서 "안다"는 필드로 갖고 있다는 뜻이 아니다 — 계산해서 답하든, 남에게 물어서
   답하든, **질문에 답할 수만 있으면** 그 정보를 아는 것이다.
3. **새 연결이 안 생기는 쪽을 고른다.** 후보가 여럿이면, 이미 관계가 있는 쪽에
   맡긴다. (상영↔예매는 이미 관계가 있다. 영화에 맡기면 영화↔예매라는 연결이
   새로 생긴다.)
4. **상관없는 일이 한 클래스에 모이지 않게 한다.** 예매 만들기와 가격 계산처럼
   성격이 다른 일이 한 클래스에 모이면 나눈다. 상관없는 일이 모인 클래스는
   기능을 추가할수록 더 뒤죽박죽이 되는 길밖에 없다.
5. **자기가 못 하는 부분은 부탁으로 넘긴다.** 상영은 요금을 모른다 → `Movie` 에게
   묻는다. 이 부탁이 `Movie` 가 새로 맡을 일이 된다. 이 반복이 설계 과정 전체다.
6. **필드는 마지막에 정한다.** 행동을 구현하다가 필요해진 것만 필드로 넣는다.

**클래스가 맡는 일(책임)은 두 종류로 나뉜다.**

- **하는 것**: 객체를 만들거나, 계산을 하거나, 다른 객체의 일을 시작시키고 조절하는 것.
- **아는 것**: 자기 상태에 대해 답하거나, 관련 정보를 알려주거나, 계산해서 알아낼 수
  있는 것을 답하는 것.

주의할 점 — "아는 것"도 **저장이 아니라 대답이라는 행동**이다. "나이를 아는 책임"을
맡았다고 해서 나이 필드를 가져야 한다는 뜻이 아니다. 필드로 갖고 답하든, 생년월일로
계산해서 답하든, 다른 객체에게 물어서 답하든 바깥에서 보기엔 완전히 같다.

**그리고 정답을 찾으려 하지 마라.** 일을 맡길 클래스를 고르는 객관적인 법칙은
존재하지 않는다. 함께 일하는 사람 대다수가 "그게 자연스럽다"고 동의하면 그것이
합리적인 설계다. 목표는 완벽한 모델이 아니라 **팀이 함께 공유하는 하나의 그림**
(공통의 멘탈 모델)을 만드는 것이고, 그 그림의 바탕이 도메인 모델이다.

협력을 설계할 때는 **CRC 카드**라는 간단한 도구를 쓸 수 있다. 카드 한 장이 객체
하나다. 위에 후보 이름(Candidate), 왼쪽에 맡을 일(Responsibility), 오른쪽에 도움을
요청할 상대(Collaborator)를 적는다. 예: 상영 카드 — 맡을 일 "상영 정보를 안다,
상영을 예매한다", 협력자 "영화". 카드에 적는 것은 클래스가 아니라 실행 중에 움직일
객체이고, 적힌 일이 메서드와 1:1 로 대응되는 것도 아니다 — 세부 구현은 잊고
큰 그림을 그리는 도구다.

**이름은 업무 용어에서 가져온다.** 여기서 업무 영역을 **도메인**이라고 부르는데,
정확히는 "소프트웨어로 구현하기로 정한 요구사항의 범위"다. 그리고 도메인의 핵심
개념과 관계만 남기고 나머지를 과감히 생략해 단순화한 그림을 **도메인 모델**이라고
한다 (지하철 노선도가 역의 순서와 연결만 남기고 실제 거리를 생략하듯이). 일을 맡길
클래스의 이름과 관계는 이 도메인 모델에서 찾는다 — 설계의 지도인 셈이다.

업무에서 "할인 정책"이라고 부르면 코드에도 `DiscountPolicy` 가 있어야 한다.
업무의 모습과 코드의 모습 사이 거리를 **표현적 차이**라고 부르는데, 이 거리가
가까울수록 "할인 조건이 바뀌었다"는 말을 듣는 순간 `DiscountCondition` 을 열면
된다는 것이 바로 떠오른다. 업무의 본질은 잘 바뀌지 않으므로, 업무를 닮은 코드
구조도 요구사항이 바뀌는 와중에 안정적으로 유지된다.
