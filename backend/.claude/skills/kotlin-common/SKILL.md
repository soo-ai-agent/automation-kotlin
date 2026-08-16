---
name: kotlin-common
description: Kotlin + Spring Boot 백엔드 전 레이어 공통 규칙. 자료형 선언, 불변성(세터 금지), 조건문·반복문 풀어쓰기(람다·함수형 체이닝 자제), 이름 규약, 예외, 주석 최소화, 검증 기준을 담는다. 이 프로젝트에서 Kotlin 코드를 작성하거나 리뷰할 때 레이어 스킬(module-layout, controller, dto, domain-service, implement, entity, repository)과 항상 함께 사용한다.
---

# 공통 규칙

## 2대 원칙

1. **단순함이 최우선.** 가장 짧게 동작하는 코드가 정답이다. 요청받지 않은 추상화·설정화·확장 지점을 만들지 않는다.

2. **데이터는 예측 가능해야 한다.** 값이 언제 어떻게 바뀌는지 코드만 보고 알 수 있어야 한다. 아무나 아무 때나 바꿀 수 있는 상태를 만들지 않는다.

## 자료형

- 공개 함수의 반환 타입, 프로퍼티 타입, 생성자 파라미터 타입은 **항상 명시한다.** 타입 추론에 맡기지 않는다.

- 지역 변수도 리터럴이 아니면 타입을 적는다.

- `Any`, `Map<String, Any>`, `List<Any>` 를 도메인 코드에서 쓰지 않는다. 필드를 아는 데이터는 필드를 적는다.

- nullable(`?`)은 "정말 없을 수 있는 값"에만 쓴다. 습관적 `?` 금지.

- `!!` 는 금지다. 필요하면 `?: throw XxxNotFoundException()` 으로 없음을 명시적으로 다룬다.

```kotlin
// ✅
fun findActive(memberId: Long): MemberResult { ... }
val names: List<String> = members.map { it.name }

// ❌ 반환 타입 생략, !! 사용
fun findActive(memberId: Long) = repository.findById(memberId).get()!!
```

## 불변성 — 세터를 만들지 않는다

- 도메인 모델·DTO·Result 는 `data class` + **`val` 만** 쓴다. `var` 금지.

- 엔티티의 변경 가능한 상태는 `var` 이되 **`protected set`** 이며, 변경은 엔티티 행위 메서드로만 한다 (kotlin-entity 참고).

- 컬렉션은 `List`/`Set`(읽기 전용)으로 노출한다. `MutableList` 를 반환하거나 프로퍼티로 공개하지 않는다.

- 값을 바꿔야 하면 `copy()` 로 새 객체를 만든다.

```kotlin
// ✅ 변경은 새 객체로
val updated: TodoResult = result.copy(done = true)

// ❌ 밖에서 아무 때나 바꿀 수 있는 상태
data class TodoResult(var done: Boolean)
```

## 조건문·반복문 — 길어도 풀어서 쓴다

- 판단·분기·누적이 들어가는 로직은 람다로 압축하지 않고 `if`/`for` 로 풀어서 쓴다. `firstOrNull { }`·`any { }`·`fold`·`filter { }.map { }` 연쇄가 대상이다.

- 기준은 글자 수가 아니라 **"처음 보는 사람이 위에서 아래로 읽으며 흐름을 따라갈 수 있는가"**다. 짧은 코드가 곧 단순한 코드가 아니다.

- 판단 없는 단순 변환 한 단계(`members.map(MemberResult::from)`)는 허용한다. 단, 체이닝을 이어붙이기 시작하면 풀어 쓴다.

- 람다가 필요해 보이는 자리(SAM 변환 등)도 이름 있는 클래스로 만들어 의도를 드러낸다.

```kotlin
// ✅ 판단이 들어가면 풀어서 쓴다 — 흐름이 그대로 보인다
var firstActive: Member? = null
for (member in members) {
    if (member.isActive) {
        firstActive = member
        break
    }
}

// ❌ 한 줄이지만 판단이 람다 안에 숨는다
val firstActive: Member? = members.firstOrNull { it.isActive }
```

## 이름

- 클래스명은 **대상(도메인/역할/책임)** 을 나타낸다: `TodoService`, `TodoFinder`, `TodoEntity`.

- 메서드명은 **그 클래스 맥락에서의 동작**을 나타낸다.

- 클래스가 대상을 충분히 설명하면 메서드는 행위 중심으로 짧게: `list`, `create`, `update`, `delete`.

- 모호하면 조건·목적·대상을 보강한다: `getById`, `listActive`, `createAdmin`, `reissueToken`.

- 도메인 용어를 클래스·메서드명에 일관되게 반영한다. 같은 개념을 두 단어로 부르지 않는다.

## 예외

- 도메인 오류는 `ApiException` 을 상속한 예외로 던진다. 그 예외가 status·code·detail 을 스스로 갖는다.

- `try/catch` 는 **처리할 수 있는 타입만** 잡는다. `catch (e: Exception)` 은 전역 핸들러(`ApiControllerAdvice`)와 배치 루프 같은 최상위 경계에서만 쓴다.

- 잡되 처리하지 않을 것은 잡지 않는다. 로그만 찍고 다시 던질 거면 `catch` 를 없앤다.

- 예외를 바꿔 던질 때 원인을 잃지 않는다: `throw XxxFailedException(cause = e)`.

- `catch` 블록에는 왜 이 타입인지, 왜 여기서 멈추는지 주석을 남긴다.

## 주석

- 주석은 **규칙을 어겼을 때와 특이사항이 있을 때만** 쓴다. 코드가 하는 일을 그대로 옮겨 적지 않는다.

- 남겨야 하는 경우: 의도적 규칙 예외, 외부 시스템의 이상 동작 우회, 성능 때문에 택한 비직관적 구현, 삭제 조건이 있는 임시 코드.

```kotlin
// ✅ 규칙 예외와 이유
// 외부 정산 API 가 5xx 를 200 으로 내려보내 본문으로 판별한다 (2026-03 벤더 확인)
if (body.code != "OK") throw ExternalCallFailedException()

// ❌ 코드를 그대로 옮긴 주석
// id 로 todo 를 찾는다
val todo: Todo = finder.getById(id)
```

## 검증

- 새 동작(분기·정책·금액·권한·상태 변경)에는 유닛 테스트를 **같은 변경에** 포함한다. 최소선은 정상 1 + 조건별 실패 각 1.

- 테스트 메서드 하나는 기능 하나만 검증한다. 상세 규칙은 `kotlin-test` 스킬을 따른다.

- 커밋 전 `./gradlew ktlintCheck unitTest` 가 통과해야 한다.

- 테스트를 지우거나 단언을 약화해 통과시키지 않는다.

## IDE 경고가 이 문서보다 우선한다

경고와 규칙이 부딪히면 **경고를 따라 코드를 고친다.** 검사를 끄는 것은 그 검사를 따르면
목적 자체가 무너질 때뿐이고, 끌 때는 `.idea/inspectionProfiles/` 에 사유를 적어 팀이 공유한다.

## 지나가기만 하는 함수는 호출부로 합친다

한 번만 쓰이면서 **이름이 본문보다 덜 말하는** 함수는 지운다.
판정은 하나 — **호출부에 그대로 넣었을 때 더 잘 읽히는가.**

이름이 공식·관용구·좌표계 변환처럼 본문이 못 보여주는 것을 담으면 남긴다.
지우는 대신 **그 데이터를 가진 타입의 메서드로 옮기는** 편이 나을 때도 있다
(`statusOf(record)` → `record.status()`).

## object 를 언제 걷고 언제 남기나

위에서부터 묻고 걸리면 멈춘다.

1. **소유할 도메인 객체가 있는가?** 있으면 그 타입의 메서드로 옮긴다.
2. **메서드 이름이 홀로 서는가?** `escape`·`normalize`·`parse` 처럼 object 이름을 빌려야
   뜻이 통하면 이름을 자립시켜 **최상위 함수**로 올린다(`escapeForJs`·`normalizeRequestPath`).
3. **같은 이름이 둘 이상이라 네임스페이스가 구분자로 일하는가?** 그때만 object 로 남긴다.
4. **상수만 모여 있는가?** 쓰는 클래스의 `companion object` 로 옮긴다.

## data class 도 메서드를 갖는다 — util 로 빼기 전에 소유자를 찾는다

**데이터만 있고 행동이 없는 타입 옆에, 그 데이터를 다루는 함수 모음이 따로 서 있으면 위반이다.**
`data class` 는 값을 담기만 하는 그릇이 아니다. 그 값으로 하는 계산은 그 타입의 메서드다.

```kotlin
// X — 좌표는 데이터, 계산은 남의 것
data class GeoPoint(val lat: Double, val lng: Double)

object SpatialMath {
    fun distanceMeters(a: GeoPoint, b: GeoPoint): Double = …
}
val d = SpatialMath.distanceMeters(from, to)
```

```kotlin
// O — 자기 값으로 하는 계산은 자기가 안다
data class GeoPoint(val lat: Double, val lng: Double) {
    fun distanceMetersTo(other: GeoPoint): Double = …
}
val d = from.distanceMetersTo(to)
```

**첫 인자가 항상 같은 타입인 함수**는 그 타입의 메서드이거나 확장 함수여야 한다는 신호다.
컬렉션을 받는 함수도 마찬가지다 — `List<GeoPoint>` 확장으로 올린다.

### util 로 내릴 것과 내리지 말 것

`support:util` 같은 공용 모듈에 내리기 전에 **소유자가 있는지 먼저 묻는다.** 판정은 하나다.

> **다른 프로젝트에 그대로 옮겨도 말이 되는가?**

| 내린다 | 내리지 않는다 |
|---|---|
| 좌표계 변환·통계 계산처럼 도메인을 모르는 순수 함수 | 우리 도메인 타입을 인자로 받는 것 — 그 타입의 메서드다 |
| 문자열·날짜·인코딩 다루기 | 우리 업무 규칙을 아는 것(임계값·가중치·정책) |
| 우리 이름을 하나도 안 쓰는 것 | 상위 계층 타입에 의존하는 것 |

**util 로 내렸는데 인자에 우리 도메인 타입이 있으면 잘못 내린 것이다.** 되돌려 소유자에게 준다.

## "없음"에 이름을 준다 — null 을 흘려보내지 않는다

값이 없는 상태에 뜻이 있으면 `null` 이 아니라 **이름**을 준다. 부르는 쪽이 `null` 을 보고
"아직인가, 끝난 건가, 실패한 건가"를 되짚게 만들지 않는다.

```kotlin
// X — 셋 다 null 이라 부르는 쪽이 구분할 수 없다
fun findLocation(token: String): LocationView?
```

```kotlin
// O — 없음에도 이름이 있다
class LocationView private constructor(…) {
    companion object {
        fun waiting(): LocationView = …          // 아직 첫 보고 전
        val EXPIRED: LocationView = …            // 기한이 지남
    }
}
```

조회 메서드의 `get`/`find` 규약(`getXxx` 는 없으면 예외, `findXxx` 는 `null`)은 그대로 지키되,
**그 없음이 화면·응답에 그대로 나가는 값이면** 이름 있는 상태로 바꾼다.

## 이름은 영어 실력과 무관하게 읽혀야 한다

표준 영어라도 추상적이면 바꾼다. 판정 순서:
중학교 영어에 나오는가 → 한국어 한 단어로 옮겨지는가 → 이미 쓰는 낱말과 겹치지 않는가.
약어는 원문이 널리 쓰이는 것만 둔다(`CSV`·`JWT`).

**예시 값을 코드에 박지 않는다.** 기본값처럼 보이는 이메일·토큰이 응답으로 새어 나간다.
환경변수로 주지 않으면 빈 값으로 둔다.

## 적발 신호

| 신호 | 문제 | 심각도 |
|---|---|---|
| 도메인 모델·DTO 에 `var` | 예측 불가능한 상태 변경 | Critical |
| `!!` 사용 | 런타임 NPE 위험 | Critical |
| `Any`·`Map<String, Any>` 로 도메인 데이터 전달 | 자료형 뭉개기 | Critical |
| 최상위 경계가 아닌 곳의 `catch (e: Exception)` | 원인 은폐 | Critical |
| 원인(`cause`) 없이 예외 교체 | 스택 유실 | Important |
| 공개 함수 반환 타입 생략 | 계약 불명확 | Important |
| 습관적 nullable(`?`) | 없음 처리 책임 전가 | Important |
| `MutableList` 노출 | 외부에서 내부 상태 변형 | Important |
| 판단·누적이 든 람다 체이닝 (`firstOrNull { }`·`fold` 등) | 흐름이 람다 안에 숨음 | Important |
| 코드를 그대로 옮긴 주석 | 소음 | Important |
| 새 동작에 유닛 테스트 없음 | 미검증 동작 유입 | Critical |

## 체크리스트

- [ ] 공개 API 의 타입이 전부 명시됐는가

- [ ] `var`·`!!`·`Any` 가 없는가

- [ ] 상태 변경이 정해진 경로(엔티티 메서드·`copy`)로만 일어나는가

- [ ] 판단·반복이 람다 없이 `if`/`for` 로 풀려 있는가

- [ ] 주석이 규칙 예외·특이사항에만 있는가

- [ ] 새 동작마다 유닛 테스트가 있고, 한 메서드가 한 기능만 검증하는가

- [ ] `./gradlew ktlintCheck unitTest` 가 통과하는가
