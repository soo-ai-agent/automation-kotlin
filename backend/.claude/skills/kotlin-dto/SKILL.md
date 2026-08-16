---
name: kotlin-dto
description: 요청·응답 DTO 작성과 리뷰 규칙. api/request 와 api/response 패키지의 data class, RequestDto·ResponseDto 이름 규약, 검증 애너테이션, 도메인 모델과의 변환 메서드를 다룰 때 사용한다. "요청 DTO 추가", "응답 형태 변경" 요청에도 사용할 것.
---

# Request / Response DTO

**자리:** `core/core-<도메인>/.../<도메인>/api/request/ · <도메인>/api/response/`

## 이름 — 접미사가 자리를 말한다

Spring 템플릿(`team-dodn/spring-boot-kotlin-template`)의 규약을 그대로 따른다. 접미사만 보면 그 타입이 어느 레이어의 것인지 알 수 있어야 한다.

| 무엇 | 접미사 | 예 | 자리 |
|---|---|---|---|
| 컨트롤러 요청 DTO | **`RequestDto`** | `TodoCreateRequestDto` | `api/request/` |
| 컨트롤러 응답 DTO | **`ResponseDto`** | `TodoResponseDto`, 중첩은 `TodoItemResponseDto` | `api/response/` |
| 외부 API 어댑터 DTO | **`RequestDto`·`ResponseDto`** | `PayRequestDto` | `clients/client-*/` |
| 도메인 입력 모델 | `Command` | `TodoCreateCommand` | `<도메인>/domain/model/` |
| 도메인 결과 모델 | **`Result`** | `TodoResult` | `<도메인>/domain/model/` |

**`Dto` 접미사는 컨트롤러·클라이언트 경계의 타입에만 붙인다.** 도메인 모델에는 붙이지 않는다 — 그 둘이 섞이면 엔티티가 밖으로 새는 것만큼이나 경계가 흐려진다.

파일 하나에 DTO 하나가 원칙이고, 파일명은 타입명과 같다. 응답 안에 중첩되는 항목 타입만 같은 파일에 둔다.

## 요청 DTO — 검증과 변환을 스스로 한다

```kotlin
data class TodoCreateRequestDto(
    @field:NotBlank(message = "제목은 필수입니다")
    @field:Size(max = 200, message = "제목은 200자를 넘을 수 없습니다")
    val title: String,
) {
    fun toCommand(): TodoCreateCommand = TodoCreateCommand(title = title.trim())
}
```

- `data class` + `val` 만. `var` 금지.

- Kotlin 에서 Bean Validation 은 **`@field:`** 접두가 필요하다. 빠뜨리면 검증이 걸리지 않는다.

- `Unresolved reference 'validation'` 이 나면 `core/core-<도메인>/build.gradle.kts` 에 `spring-boot-starter-validation` 이 빠진 것이다.

  이 의존성은 사람이 뼈대를 만들 때 넣는다 (`backend/README.md` 2절).

- 애너테이션으로 표현되는 규칙(필수·길이·범위·형식)은 애너테이션으로 쓴다. 그것으로 안 되는 규칙(공백만 입력 등)은 변환 메서드나 도메인에서 다룬다.

- 도메인 입력 모델로 바꾸는 `toXxx()` 를 DTO 가 가진다. 컨트롤러가 손으로 조립하지 않는다.

## 응답 DTO — 도메인 결과에서 만든다

```kotlin
data class TodoResponseDto(
    val id: Long,
    val title: String,
    val done: Boolean,
    val createdAt: LocalDateTime,
) {
    companion object {
        fun from(result: TodoResult): TodoResponseDto = TodoResponseDto(
            id = result.id,
            title = result.title,
            done = result.done,
            createdAt = result.createdAt,
        )
    }
}
```

- 변환은 `companion object` 의 `from(result)` 로 통일한다.

- **엔티티에서 바로 만들지 않는다.** 입력은 항상 도메인 모델(Result)이다.

- 응답에 비밀번호 해시·내부 식별자·감사 컬럼 같은 내부 정보를 담지 않는다.

- 필드 타입을 명시하고 nullable 을 최소화한다. 없을 수 있는 값만 `?`.

- **`?` 필드는 선언 바로 위에 사유를 적는다.** 문장은 `<언제> null 이 가능함` 꼴로 끝낸다.
  클래스 위에 한 줄로 몰아 적으면 어느 필드 이야기인지 흐려진다.

  ```kotlin
  data class SlackConfigSummary(
      val webhookConfigured: Boolean,
      // 웹훅을 설정하지 않으면 null 이 가능함
      val webhookMasked: String?,
  )
  ```

- **요청 DTO 의 검증 대상은 nullable 로 둔다.** `@field:NotNull val quantity: Int?` 에서 `?` 를
  지우면 안 된다. Kotlin non-null 원시 타입은 값이 없을 때 예외가 아니라 **기본값이 들어간다**
  (`Int`·`Double` 은 `0`, `Boolean` 은 `false`). 그래서 필드를 통째로 안 보낸 요청이
  "값이 없습니다" 가 아니라 **0 을 보낸 요청과 똑같이** 처리되고, 엉뚱한 곳에서 다른 메시지로
  실패한다. nullable + `@NotNull` 이면 어느 필드가 빠졌는지 응답에 담긴다.
  요청 DTO 안의 `Int`·`Double`·`Boolean` 은 non-null 로 선언하지 않는다.

## 적발 신호

| 신호 | 문제 | 심각도 |
|---|---|---|
| DTO 에 `var` | 예측 불가능한 상태 변경 | Critical |
| 응답 DTO 가 엔티티를 입력으로 받음 | 저장소 격리 붕괴 | Critical |
| 비밀번호·해시·내부 필드 노출 | 정보 유출 | Critical |
| `@field:` 없는 검증 애너테이션 | 검증이 동작하지 않음 | Critical |
| DTO 이름에 `RequestDto`·`ResponseDto` 접미사 없음 | 템플릿 규약 위반 — 경계가 이름으로 안 보임 | Important |
| 도메인 모델(`Command`·`Result`)에 `Dto` 접미사 | 컨트롤러 경계 타입과 혼동 | Important |
| 변환 로직이 컨트롤러에 흩어짐 | 중복·불일치 | Important |
| 검증 메시지 없음 | 클라이언트가 원인 모름 | Important |
| 습관적 nullable 필드 | 계약 불명확 | Important |

## 체크리스트

- [ ] 모든 필드가 `val` 이고 타입이 명시됐는가

- [ ] 검증 애너테이션에 `@field:` 가 붙었는가

- [ ] 이름이 `RequestDto`·`ResponseDto` 로 끝나는가 (도메인 모델은 `Command`·`Result`)

- [ ] 요청은 `toXxx()`, 응답은 `from(result)` 로 변환하는가

- [ ] 내부 정보가 응답에 없는가
