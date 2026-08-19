---
name: kotlin-client
description: 외부 시스템 연동 규칙. 처음 붙이는 API 를 실응답부터 확인하는 절차(필드명·타입·페이징·빈 결과·좌표계, 규격 위반 대응), 쿼터·갱신 주기에 맞춘 호출 설계, 0건·실패가 기존 데이터를 지우지 않게 하기, 조용한 폴백 금지, clients/client-* 모듈의 구조와 internal 캡슐화, 타임아웃, 외부 실패를 ApiException 하위 예외로 번역하기, 트랜잭션 안에서 호출 금지, 카탈로그(docs/external-apis.md) 기록을 다룬다. 외부 API·결제·알림 연동을 붙일 때 사용한다. "외부 API 연동", "RestClient", "결제 붙이기", "이 데이터 어디서 오나" 요청에도 사용할 것.
---

# 외부 시스템 연동 (clients)

**자리:** `clients/client-<이름>/.../client/<이름>/`

## 모듈 하나가 외부 시스템 하나

**외부와 통신하는 코드는 예외 없이 이 `clients` 모듈에 둔다.** HTTP 든 SDK 든 소켓이든,
도메인(core)·storage·support 모듈 안에서 외부를 직접 부르는 코드가 보이면 그 자리에서
`clients/client-<이름>` 으로 옮긴다 — "작은 호출이라 그냥 뒀다"는 예외를 만들지 않는다.

결제, 알림, 지도처럼 붙일 외부 시스템마다 모듈을 만든다. `settings.gradle.kts` 에 `clients:client-<이름>` 을 등록하고, 그 외부 시스템을 부르는 도메인 모듈이 `implementation` 으로 가져다 쓴다.

한 모듈 안의 파일은 넷이다. **역할이 겹치지 않게 나뉘어 있고, 그중 밖으로 나가는 것은 둘뿐이다.**

| 파일 | 역할 | 공개 범위 |
|---|---|---|
| `<이름>ApiSpec.kt` | 엔드포인트·옵션 상수. 외부 규격이 바뀌면 여기만 고친다 | **`internal`** |
| `<이름>Request.kt`·`<이름>Response.kt` | 외부가 요구하는·주는 JSON 모양 | **`internal`** |
| `<이름>Client.kt` | `RestClient` 로 호출하고 우리 말로 번역한다 | 공개 |
| `<이름>Client.kt` | 바깥이 부르는 유일한 창구 | `public` |
| `model/<이름>ClientResult.kt` | 바깥으로 나가는 결과 모델 | `public` |

## 처음 붙이는 API 는 문서보다 실응답이 먼저다

**문서가 말하는 모양과 실제로 오는 바이트는 자주 다르다.** 코드를 쓰기 전에 실응답을 한 번 떠서 파일로 남기고, 그것을 보고 DTO 를 만든다.

```bash
curl -sS "<엔드포인트>" -H "<인증 헤더>" | tee /tmp/sample.json | head -c 2000
```

응답을 받으면 다섯 가지를 확인한다. 이것들이 나중에 "왜 안 되는지 모르겠다"로 돌아온다.

| 확인할 것 | 왜 |
|---|---|
| 필드 이름 — 영문·현지어가 섞여 오는가 | 한쪽만 매핑하면 어떤 건은 통째로 비어 온다 |
| 숫자·불리언이 문자열로 오는가 | `"0"`·`"Y"` 를 숫자·불리언으로 선언하면 파싱이 깨진다 |
| 목록의 페이징 — 총건수·커서·페이지 크기 상한 | 첫 페이지만 받고 "데이터가 적다"고 오해한다 |
| 빈 결과의 모양 — 빈 배열인가, 필드 자체가 없는가, 에러인가 | 빈 결과를 실패로 처리하면 조용한 장애가 된다 |
| 좌표·단위·시간대 | 문서에 안 적힌 경우가 많다. **알려진 값으로 왕복시켜 검산**한다 |

**규격 위반을 가정한다.** 제어문자가 섞여 오는 응답이 실제로 있다 — JSON 규격상 이스케이프돼야 하는 문자가 날것으로 오면 파서가 본문 전체를 거부한다. 이럴 때는 **문자열로 먼저 받아 다듬은 뒤 파싱**하고, 그 우회는 `internal` 안에서 끝낸다(도메인은 이런 사정을 몰라야 한다).

## 쿼터와 갱신 주기가 호출 설계를 정한다

호출 한도가 있거나 원본이 자주 안 바뀌면, **화면 요청마다 부르지 않는다.**

- 원본이 월 단위로 갱신되는데 요청마다 부르면 한도만 태우고 결과는 같다 — 주기적으로 받아 저장하고, 화면은 저장된 것을 읽는다.

- 갱신에 실패하거나 **0건이 오면 기존 데이터를 유지한다.** 0건을 성공으로 받아 통째로 교체하면 멀쩡하던 데이터가 사라진다.

- **원천이 여럿이면 원천별로 독립 게이트를 둔다.** 하나가 죽어도 나머지는 살아야 하고, 키가 없는 원천은 그 원천만 건너뛴다.

## 대량 호출은 시작 전에 승인받는다

**외부 API 를 30건 이상 호출하는 작업은 시작 전에 사람에게 보고하고 승인을 받는다.**

보고에 셋을 담는다.

1. **대상** — 어떤 외부 시스템의 어떤 엔드포인트인가.

2. **예상 호출 수** — 몇 건인가. 모르면 상한을 계산해서 적는다("최대 N페이지 × M건").

3. **쿼터 영향** — 일·월 한도의 몇 %를 쓰는가. 유료면 예상 비용도.

**실검증도 예외가 아니다.** "실제로 되는지 확인해 보려고"가 가장 흔한 예외 주장인데, 태운 쿼터는
되돌릴 수 없다. 하루 한도를 검증 한 번으로 소진하면 그날 개발도 운영도 멈춘다.

승인 전에는 **1건**으로 확인한다 — 응답 모양·인증·페이징은 한 건이면 다 드러난다.
그 한 건으로 안 되는 것만 승인을 받아 돌린다.

건수가 30 미만이어도 **유료 호출이거나 비멱등(결제·발송)이면** 같은 절차를 밟는다.

Claude 세션에는 `.claude/hooks/warn-bulk-api-calls.sh` 훅이 걸려 있어 "반복 + HTTP 호출" 명령에서
확인 창이 뜬다. 그 창이 안 떴다고 승인이 필요 없다는 뜻은 아니다 — 훅은 명령줄만 보고,
스크립트·배치 안의 호출은 모른다.

## 폴백은 조용하면 안 된다

대체 경로로 빠졌다는 사실을 사람이 알아야 한다. 로그만 남기고 넘어가면 **"잘 되고 있음"으로 보이는 고장**이 된다.

폴백·전면 실패·갱신 0건에는 알림을 붙인다(`kotlin-logging`, `support:monitoring`). 반복 알림은 스로틀로 줄이되, 없애지는 않는다.

## 붙였으면 카탈로그에 적는다

새 외부 시스템을 붙이면 [docs/external-apis.md](../../../../docs/external-apis.md) 에 한 줄 추가한다.

다음 사람이 "이 데이터가 어디서 오는지", "키가 어디 있는지", "막히면 무엇이 대신 나가는지"를 코드를 뒤지지 않고 알 수 있어야 한다.

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
internal data class ExampleResponse(val exampleResponseValue: String) {
    fun toResult(): ExampleClientResult = ExampleClientResult(exampleResponseValue)
}

// ✅ 밖에서 보이는 것 — 이것만
@Component
class ExampleClient internal constructor(
    private val exampleApi: ExampleApi,
) {
    fun example(parameter: String): ExampleClientResult {
        return exampleApi.example(ExampleRequest(parameter)).toResult()
    }
}
```

`internal constructor` 를 쓴 이유는, 클래스는 공개하되 **`internal` 타입을 받는 생성자는 감춰야** 하기 때문이다. 스프링은 그대로 주입한다.

변환 메서드(`toResult()`)는 `Response` 가 갖는다 — DTO 가 자기 변환을 아는 것은 `kotlin-dto` 와 같은 규칙이다.

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

## 알림 웹훅도 clients 에 둔다 — 인터페이스만 support 에

관측 채널(Slack 등)도 외부 호출이므로 `clients:client-<이름>` 이 소유한다.
단 알림 **계약**(인터페이스·이력 레코드)은 `support:monitoring` 에 남긴다 —
소비자(core)는 support 의 인터페이스만 알고, clients 모듈이 그것을 구현한다
(clients → support 의존은 허용 방향이다). 설정(웹훅 URL·스로틀)도 그 모듈의 yml 이 소유한다.

## 적발 신호

| 신호 | 문제 | 심각도 |
|---|---|---|
| 도메인(core)·storage·support 모듈 안의 외부 호출 코드 | 외부 연동은 clients 전용 — 즉시 이동 | Critical |
| `@Transactional` 안에서 외부 호출 | 외부 장애가 DB 커넥션 고갈로 전파 | Critical |
| RestClient 호출부·DTO 가 `public` | 외부 JSON 규격이 도메인으로 샘 | Critical |
| 타임아웃 미설정 | 응답 없는 외부에 스레드가 묶임 | Critical |
| `RestClientException` 이 도메인까지 올라감 | 도메인이 외부 라이브러리를 알게 됨 | Critical |
| 외부 응답 원문을 사용자 응답에 그대로 노출 | 내부 주소·키 유출 | Critical |
| 비멱등 호출(결제·발송)에 재시도 | 중복 처리 | Critical |
| 갱신 0건·실패를 성공으로 받아 기존 데이터 교체 | 멀쩡하던 데이터가 사라진다 | Critical |
| 알림 없는 조용한 폴백 | 고장이 정상으로 보인다 | Critical |
| 코드에 외부 URL 하드코딩 | 환경별 전환 불가 | Important |
| 승인 없이 외부 API 를 30건 이상 호출 (실검증 포함) | 되돌릴 수 없는 쿼터·비용 소진 | Critical |
| 한도 있는 API 를 화면 요청마다 호출 | 쿼터 소진 — 주기 갱신 + 저장으로 | Important |
| 실응답을 안 보고 문서만 보고 만든 DTO | 필드명·타입이 어긋나 조용히 빈 값 | Important |
| 붙인 외부 시스템이 카탈로그에 없음 | 다음 사람이 코드를 뒤져야 한다 | Important |
| 도메인 서비스가 `Client` 를 직접 호출 | 구현 레이어 건너뛰기 | Important |
| `ClientResult` 없이 통신 `Response` 를 그대로 반환 | 모듈 경계 붕괴 | Important |

## 체크리스트

- [ ] RestClient 호출부·DTO·Config 가 `internal` 인가

- [ ] 바깥에 나가는 것이 `Client` 와 `model/*ClientResult` 뿐인가

- [ ] `connectTimeout`·`readTimeout` 을 설정했는가

- [ ] 외부 예외를 `ApiException` 하위 예외 으로 바꾸면서 원인을 안고 가는가

- [ ] 트랜잭션 밖에서 호출하는가

- [ ] 재시도를 걸었다면 그 호출이 멱등한가

- [ ] 실응답을 실제로 떠 보고 DTO 를 만들었는가(필드명·타입·페이징·빈 결과)

- [ ] 0건·실패 응답이 기존 데이터를 지우지 않는가

- [ ] 폴백으로 빠질 때 사람에게 알리는가

- [ ] 30건 이상 호출할 일이 있었다면 대상·예상 호출 수·쿼터 영향을 보고하고 승인받았는가

- [ ] `docs/external-apis.md` 에 한 줄 추가했는가
