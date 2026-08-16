---
name: kotlin-error
description: 실패를 표현하는 규칙. 예외가 자기 응답(status·code·title·detail)을 갖는 ApiException 베이스, 예외를 던지는 도메인이 소유하는 규칙, 새 실패 유형을 추가하는 순서, HTTP 상태코드와 로그 레벨 고르는 기준, ApiControllerAdvice 핸들러, 응답 메시지에 담아도 되는 것을 다룬다. 기능에 실패 분기를 만들 때 kotlin-domain-service 와 함께 사용한다. "예외 처리", "에러 응답", "404 를 주고 싶다" 요청에도 사용할 것.
---

# 에러 설계

**자리:** 베이스는 `core:core-common/.../common/error/`, 구체 예외는 **던지는 도메인**의 `domain/error/`

## 예외가 자기 응답을 안다 — 핸들러를 늘리지 않는다

`@RestControllerAdvice` 에 예외 종류마다 핸들러를 더하고 있다면, advice 가 종류를 확인해
대신 결정하고 있는 것이다. 그 값을 **예외가 들고 오게** 한다.

```kotlin
abstract class ApiException(
    val status: HttpStatus,
    val code: String,
    val detail: String,                       // 사용자 문구(내부 수치 없음)
    val fieldErrors: List<ApiFieldError> = emptyList(),
    message: String = detail,                 // 로그용. 내부 값을 담아도 된다
    cause: Throwable? = null,                 // 외부 예외를 감쌀 때 원인을 잃지 않게
) : RuntimeException(message, cause)

// 응답에 나가는 값(code·detail·fieldErrors)만 갖는다.
// 응답에 안 쓰는 필드를 여기 두면 죽은 값이 된다
```

advice 는 종류를 묻지 않고 값만 옮겨 담는다. 새 예외를 추가해도 핸들러는 늘지 않는다.

```kotlin
@ExceptionHandler(ApiException::class)
fun handleApiException(e: ApiException): ResponseEntity<ApiResponse<Any>> = …   // 이 하나로 끝난다
```

**프레임워크 예외**는 `ApiException` 을 상속할 수 없어 개별 핸들러가 남는다.
필요한 것은 둘뿐이고, 그 외에는 늘리지 않는다.

| 프레임워크 예외 | 언제 | 응답 |
|---|---|---|
| `MethodArgumentNotValidException` | `@Valid` 검증 실패 | 400 + fieldErrors |
| `HttpMessageNotReadableException` | 본문 누락·깨진 JSON | 400 (없으면 **500 으로 나간다** — 실측) |

## 예외는 던지는 도메인이 소유한다

`throw` 하는 모듈을 센다.

| 던지는 모듈 | 사는 곳 |
|---|---|
| 한 도메인 | 그 도메인의 `domain/error/` |
| 둘 이상 | 공용 모듈 |
| 베이스·공용 값(`ApiException`·`ApiFieldError`) | 공용 모듈 |

`api/request` 에서 던지는 예외도 `domain/error` 에 둔다(api → domain 은 허용 방향).
**옮긴 뒤 "다른 도메인이 이 예외를 import 하는가"를 세어 0인지 확인한다.**

## 새 실패를 만났을 때 — 순서대로

**1. 이미 있는 예외가 스스로 가진 status·code 으로 되는지 본다.** "할 일이 없음"과 "회원이 없음"이 클라이언트에게 똑같이 취급된다면 하나로 충분하다. 매번 새로 만들면 코드만 늘고 분기는 못 한다.

**2. 안 되면 셋을 함께 추가한다.**

```kotlin
// core/core-<도메인>/.../<도메인>/domain/error/TodoNotFoundException.kt
class TodoNotFoundException(todoId: Long) : ApiException(
    status = HttpStatus.NOT_FOUND,
    code = "TODO_NOT_FOUND",
    detail = "할 일을 찾을 수 없습니다.",      // 사용자에게 보이는 문구
    message = "할 일이 없다: id=$todoId",      // 로그용. 내부 값을 담아도 된다
)
```

`code` 는 클라이언트가 분기에 쓰는 문자열이다. `E404` 같은 상태코드 재탕이 아니라
**무엇이 잘못됐는지**를 말하는 이름으로 짓는다(`TODO_NOT_FOUND`·`INVALID_ISBN`).

**3. 도메인에서 던진다.** 던지는 자리는 그 실패를 처음 아는 곳이다 — 보통 구현 레이어나 도메인 서비스다.

```kotlin
fun find(id: Long): Todo {
    val entity: TodoEntity = todoRepository.findOneById(id)
        ?: throw TodoNotFoundException(id)
    return entity.toModel()
}
```

## 상태코드 고르기

| 상황 | 상태 | 로그 레벨 |
|---|---|---|
| 요청 값이 형식·검증에 어긋남 | 400 | `WARN` |
| 로그인하지 않았거나 토큰이 만료됨 | 401 | `WARN` |
| 로그인했지만 권한이 없음 (남의 데이터) | 403 | `WARN` |
| 대상이 없음 | 404 | `WARN` |
| 이미 있음·상태가 맞지 않아 못 함 (중복 가입, 이미 완료) | 409 | `WARN` |
| 우리 코드나 외부 시스템이 잘못됨 | 500 | `ERROR` |

**로그 레벨의 기준은 하나다 — "새벽에 깨워야 하는가."**

사용자가 잘못 보낸 요청(4xx)은 정상 동작이므로 `WARN` 이나 `INFO` 다. `ERROR` 는 **우리가 고쳐야 할 것**에만 쓴다. 4xx 를 `ERROR` 로 찍으면 진짜 장애가 로그에 묻힌다.

## 응답 메시지에 담아도 되는 것

`ApiException.message` 는 **사용자에게 그대로 보인다.**

- 담는다: 무엇이 잘못됐고 무엇을 하면 되는지. "할 일을 찾을 수 없습니다."

- 담지 않는다: 스택 트레이스, SQL, 내부 ID, 파일 경로, 다른 사람의 개인정보.

특히 **"없음"과 "권한 없음"을 구분해 알려주면 남의 데이터 존재 여부가 새어 나간다.** 소유자 스코프가 있는 조회는 둘 다 404 로 응답하는 편이 안전하다.

필드별 사유가 필요하면 `ApiException.fieldErrors` 에 담는다 — 검증 실패가 그 예다.

## 검증 실패 핸들러

`@Valid` 가 걸리면 스프링이 `MethodArgumentNotValidException` 을 던지는데, 템플릿 `ApiControllerAdvice` 에는 이 핸들러가 없다.

없으면 400 이 응답 DTO 형태가 아닌 스프링 기본 응답으로 나가고 **프론트 `apiClient` 가 껍데기를 벗기지 못한다.** 뼈대를 만들 때 넣는다 (`backend/README.md` 2절).

검증 실패도 `ApiException` 하위 예외로 바꿔 던지면, 응답을 만드는 자리가 한 곳으로 유지된다.

```kotlin
// 공용 모듈 — 프레임워크 검증 실패를 우리 예외로 옮긴다
class RequestValidationException(fieldErrors: List<ApiFieldError>) :
    ApiException(
        status = HttpStatus.BAD_REQUEST,
        code = "INVALID_REQUEST",
        detail = "요청 값을 확인해 주세요.",
        fieldErrors = fieldErrors,
        message = "요청 검증 실패",
    )
```

```kotlin
// 포괄 Exception 핸들러보다 위에 둔다
@ExceptionHandler(MethodArgumentNotValidException::class)
fun handleValidationFailure(e: MethodArgumentNotValidException): ResponseEntity<ApiResponse<Any>> {
    val fieldErrors: MutableList<ApiFieldError> = mutableListOf()
    for (fieldError in e.bindingResult.fieldErrors) {
        val message: String = fieldError.defaultMessage ?: "올바르지 않은 값입니다."
        fieldErrors.add(ApiFieldError(fieldError.field, message))
    }
    return respond(RequestValidationException(fieldErrors))
}
```

**`:` 앞에서 줄을 바꾼 것에 이유가 있다.** 클래스 선언 줄이 길어지면 ktlint 가
`Super type should start on a newline` 으로 막는다. 생성자 인자가 있는 예외는 위 형태로 쓴다.

핸들러는 **좁은 예외부터 위에, 포괄 `Exception` 은 맨 아래**에 둔다. 순서가 바뀌면 좁은 핸들러가 영영 안 걸린다.

## 잡지 말아야 할 것

- **컨트롤러에서 `try/catch` 하지 않는다.** `ApiControllerAdvice` 가 한 곳에서 번역한다.

- `catch (e: Exception)` 는 전역 핸들러·배치 루프 같은 최상위 경계에서만 쓴다. 그 자리에서도 원인을 로그로 남긴다.

- 예외를 바꿔 던질 때 **원인을 버리지 않는다.**

```kotlin
// ❌ 원래 무엇이 터졌는지 영영 알 수 없다
catch (e: IOException) { throw UnexpectedServerException() }

// ✅ 원인을 안고 간다
catch (e: IOException) { throw UnexpectedServerException(cause = e) }
```

`ApiException` 하위 예외 에 원인을 넘길 자리가 없으면 그 자리를 만든다.

## 적발 신호

| 신호 | 문제 | 심각도 |
|---|---|---|
| 컨트롤러의 `try/catch` | 예외 처리 중복·누락 | Critical |
| 사유 주석 없는 `catch (e: Exception)` | 진짜 장애가 묻힘 | Critical |
| 원인(`cause`)을 버리는 예외 교체 | 디버깅 불가 | Critical |
| 예외 메시지에 스택·SQL·내부 ID·개인정보 | 정보 유출 | Critical |
| 소유자 스코프 조회에서 403 과 404 를 구분해 응답 | 남의 데이터 존재 여부 노출 | Critical |
| 좁은 핸들러가 포괄 `Exception` 핸들러 아래에 있음 | 좁은 핸들러가 안 걸림 | Critical |
| 4xx 상황을 `LogLevel.ERROR` 로 | 진짜 장애가 로그에 묻힘 | Important |
| 도메인 실패에 `DEFAULT_ERROR` 재사용 | 클라이언트가 분기 불가 | Important |
| 실패마다 예외가 스스로 가진 status·code 을 새로 만듦 | 코드만 늘고 구분은 안 됨 | Important |
| 서비스가 `HttpStatus`·`ResponseEntity` 를 직접 다룸 | 레이어 침범 | Important |

## 체크리스트

- [ ] 새 실패가 기존 예외가 스스로 가진 status·code 으로 안 되는 것이 확실한가

- [ ] 상태코드와 로그 레벨이 위 표 기준과 맞는가 (4xx 는 `ERROR` 가 아니다)

- [ ] 메시지에 내부 정보·개인정보가 없는가

- [ ] 소유자 스코프 조회가 "없음"과 "권한 없음"을 구분해 흘리지 않는가

- [ ] 예외를 바꿔 던질 때 원인을 안고 가는가

- [ ] 컨트롤러에 `try/catch` 가 없는가
