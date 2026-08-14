---
name: kotlin-dto
description: 요청·응답 DTO 작성과 리뷰 규칙. controller/v1/request 와 response 패키지의 data class, 검증 애너테이션, 도메인 모델과의 변환 메서드를 다룰 때 사용한다. "요청 DTO 추가", "응답 형태 변경" 요청에도 사용할 것.
---

# Request / Response DTO

**자리:** `core/core-api/.../core/api/controller/v1/request|response/`

## 요청 DTO — 검증과 변환을 스스로 한다

```kotlin
data class TodoCreateRequest(
    @field:NotBlank(message = "제목은 필수입니다")
    @field:Size(max = 200, message = "제목은 200자를 넘을 수 없습니다")
    val title: String,
) {
    fun toCommand(): TodoCreateCommand = TodoCreateCommand(title = title.trim())
}
```

- `data class` + `val` 만. `var` 금지.

- Kotlin 에서 Bean Validation 은 **`@field:`** 접두가 필요하다. 빠뜨리면 검증이 걸리지 않는다.

- 애너테이션으로 표현되는 규칙(필수·길이·범위·형식)은 애너테이션으로 쓴다. 그것으로 안 되는 규칙(공백만 입력 등)은 변환 메서드나 도메인에서 다룬다.

- 도메인 입력 모델로 바꾸는 `toXxx()` 를 DTO 가 가진다. 컨트롤러가 손으로 조립하지 않는다.

## 응답 DTO — 도메인 결과에서 만든다

```kotlin
data class TodoResponse(
    val id: Long,
    val title: String,
    val done: Boolean,
    val createdAt: LocalDateTime,
) {
    companion object {
        fun from(result: TodoResult): TodoResponse = TodoResponse(
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

## 적발 신호

| 신호 | 문제 | 심각도 |
|---|---|---|
| DTO 에 `var` | 예측 불가능한 상태 변경 | Critical |
| 응답 DTO 가 엔티티를 입력으로 받음 | 저장소 격리 붕괴 | Critical |
| 비밀번호·해시·내부 필드 노출 | 정보 유출 | Critical |
| `@field:` 없는 검증 애너테이션 | 검증이 동작하지 않음 | Critical |
| 변환 로직이 컨트롤러에 흩어짐 | 중복·불일치 | Important |
| 검증 메시지 없음 | 클라이언트가 원인 모름 | Important |
| 습관적 nullable 필드 | 계약 불명확 | Important |

## 체크리스트

- [ ] 모든 필드가 `val` 이고 타입이 명시됐는가

- [ ] 검증 애너테이션에 `@field:` 가 붙었는가

- [ ] 요청은 `toXxx()`, 응답은 `from(result)` 로 변환하는가

- [ ] 내부 정보가 응답에 없는가
