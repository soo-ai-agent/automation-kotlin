---
name: kotlin-client
description: 외부 시스템 연동 규칙. clients/client-* 모듈의 구조(Api·Client·Config·Dto·model), internal 로 RestClient 호출부와 DTO 를 모듈 안에 가두는 법, 타임아웃 설정, 외부 실패를 ApiException 하위 예외 으로 번역하기, 트랜잭션 안에서 호출 금지를 다룬다. 외부 API·결제·알림 연동을 붙일 때 사용한다. "외부 API 연동", "RestClient", "결제 붙이기" 요청에도 사용할 것.
---

# 외부 시스템 연동 (clients)

**자리:** `clients/client-<이름>/.../client/<이름>/`

## 모듈 하나가 외부 시스템 하나

결제, 알림, 지도처럼 붙일 외부 시스템마다 모듈을 만든다. `settings.gradle.kts` 에 `clients:client-<이름>` 을 등록하고, `core-api` 가 그것을 `implementation` 으로 가져다 쓴다.

한 모듈 안의 파일은 넷이다. **역할이 겹치지 않게 나뉘어 있고, 그중 밖으로 나가는 것은 둘뿐이다.**

| 파일 | 역할 | 공개 범위 |
|---|---|---|
| `<이름>ApiSpec.kt` | 엔드포인트·옵션 상수. 외부 규격이 바뀌면 여기만 고친다 | **`internal`** |
| `<이름>RequestDto.kt`·`<이름>ResponseDto.kt` | 외부가 요구하는·주는 JSON 모양 | **`internal`** |
| `<이름>Client.kt` | `RestClient` 로 호출하고 우리 말로 번역한다 | 공개 |
| `<이름>Client.kt` | 바깥이 부르는 유일한 창구 | `public` |
| `model/<이름>ClientResult.kt` | 바깥으로 나가는 결과 모델 | `public` |

## 핵심 — `internal` 로 외부 규격을 가둔다

**외부 API 의 JSON 모양이 우리 도메인으로 새어 들어오면 안 된다.** 외부가 필드 이름을 바꾸면 우리 서비스까지 고쳐야 하기 때문이다.

HTTP 호출은 **`RestClient`** 로 한다(RestClient 아님). 자동구성된 `RestClient.Builder` 를 주입받아
`clone().build()` 로 쓰면 타임아웃 같은 전역 설정이 한곳에서 걸린다.

그래서 통신 DTO 를 `internal` 로 막고, `Client` 가 우리 말로 번역한 결과만 내보낸다.

**외부 응답을 문자열로 먼저 받아야 할 때가 있다.** 규격을 어긴 본문(제어문자 등)이 오면
바로 파싱하다 실패하고, 그 실패가 겉면 메시지에 가려 원인이 안 보인다. 실제로 겪은 사례가 있어
**외부 호출 실패 로그에는 원인 사슬(cause)까지 남긴다** — `e.message` 만 남기면 진짜 원인이 사라진다.

```kotlin
// ❌ 밖에서 보이면 안 되는 것들
internal interface ExampleApi { ... }
internal data class ExampleResponseDto(val exampleResponseValue: String) {
    fun toResult(): ExampleClientResult = ExampleClientResult(exampleResponseValue)
}

// ✅ 밖에서 보이는 것 — 이것만
@Component
class ExampleClient internal constructor(
    private val exampleApi: ExampleApi,
) {
    fun example(parameter: String): ExampleClientResult {
        return exampleApi.example(ExampleRequestDto(parameter)).toResult()
    }
}
```

`internal constructor` 를 쓴 이유는, 클래스는 공개하되 **`internal` 타입을 받는 생성자는 감춰야** 하기 때문이다. 스프링은 그대로 주입한다.

변환 메서드(`toResult()`)는 `ResponseDto` 가 갖는다 — DTO 가 자기 변환을 아는 것은 `kotlin-dto` 와 같은 규칙이다.

## 도메인에서 부르는 자리

`Client` 는 **구현 레이어**가 부른다. 도메인 서비스가 직접 부르지 않는다 — 리포지토리를 직접 부르지 않는 것과 같은 이유다.

```
도메인 서비스 → XxxSender(구현 레이어) → ExampleClient → 외부
```

구현 레이어가 `ClientResult` 를 도메인 모델로 한 번 더 바꾼다. 그래야 외부 모듈 타입이 도메인 서비스 시그니처에 안 나온다.

## 타임아웃은 반드시 건다

기본값에 맡기면 외부가 응답하지 않을 때 **우리 스레드가 통째로 묶인다.** 설정은 그 모듈의 yml 에 둔다 (`kotlin-config`).

```yaml
spring.cloud.openfeign:
  client:
    config:
      example-api:                # RestClient 의 value 와 같아야 한다
        connectTimeout: 2100
        readTimeout: 5000
```

- 주소는 `${example.api.url}` 처럼 자리만 두고 프로파일별로 채운다. **코드에 URL 을 박지 않는다.**

- `readTimeout` 은 상대의 응답 시간을 재서 정한다. 모르면 짧게 잡고 늘린다 — 길게 잡으면 장애가 전파된다.

## 실패를 우리 말로 번역한다

외부 예외(`RestClientException`)가 도메인까지 올라가면, 도메인이 외부 라이브러리를 알게 된다.

`Client` 나 구현 레이어에서 잡아 `ApiException` 하위 예외 으로 바꾼다 (`kotlin-error`).

```kotlin
try {
    return exampleApi.example(request).toResult()
} catch (e: RestClientException) {
    throw ExampleApiFailedException(cause = e)   // 원인을 안고 간다
}
```

- 외부가 준 원문 메시지를 사용자 응답에 그대로 싣지 않는다. 내부 주소·키가 섞여 나올 수 있다.

- 재시도는 **멱등한 호출에만** 건다. 결제 승인처럼 두 번 부르면 안 되는 것에 재시도를 걸지 않는다.

## 트랜잭션 안에서 부르지 않는다

DB 트랜잭션을 열어 둔 채 외부를 호출하면, 외부가 느린 만큼 **커넥션과 락을 잡고 있는다.** 외부 장애가 DB 고갈로 번진다.

트랜잭션은 짧게 끊고, 외부 호출은 그 밖에서 한다 (`kotlin-domain-service`).

## 적발 신호

| 신호 | 문제 | 심각도 |
|---|---|---|
| `@Transactional` 안에서 외부 호출 | 외부 장애가 DB 커넥션 고갈로 전파 | Critical |
| RestClient 호출부·DTO 가 `public` | 외부 JSON 규격이 도메인으로 샘 | Critical |
| 타임아웃 미설정 | 응답 없는 외부에 스레드가 묶임 | Critical |
| `RestClientException` 이 도메인까지 올라감 | 도메인이 외부 라이브러리를 알게 됨 | Critical |
| 외부 응답 원문을 사용자 응답에 그대로 노출 | 내부 주소·키 유출 | Critical |
| 비멱등 호출(결제·발송)에 재시도 | 중복 처리 | Critical |
| 코드에 외부 URL 하드코딩 | 환경별 전환 불가 | Important |
| 도메인 서비스가 `Client` 를 직접 호출 | 구현 레이어 건너뛰기 | Important |
| `ClientResult` 없이 `ResponseDto` 를 그대로 반환 | 모듈 경계 붕괴 | Important |

## 체크리스트

- [ ] RestClient 호출부·DTO·Config 가 `internal` 인가

- [ ] 바깥에 나가는 것이 `Client` 와 `model/*ClientResult` 뿐인가

- [ ] `connectTimeout`·`readTimeout` 을 설정했는가

- [ ] 외부 예외를 `ApiException` 하위 예외 으로 바꾸면서 원인을 안고 가는가

- [ ] 트랜잭션 밖에서 호출하는가

- [ ] 재시도를 걸었다면 그 호출이 멱등한가
