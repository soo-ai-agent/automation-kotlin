---
name: api-contract
description: 서버와 클라이언트가 주고받는 데이터의 계약 규칙. CONTRACT.md 와 백엔드 응답 DTO 코드를 기준으로 한 미러링, nullable 대칭, 미지의 enum 정규화, 검증·변환의 자리, 와이어 단위(시각·금액), 필드 추가·삭제 절차를 다룬다. API 타입·DTO·필드를 추가·변경하거나 "서버랑 타입이 안 맞아", "정합성" 문제를 다룰 때 반드시 사용할 것. 서버 쪽 상세는 kotlin-dto·kotlin-style, 클라이언트 쪽 상세는 frontend-react 11장·frontend-style 이 담당한다.
---

# 서버-클라이언트 계약

**원칙 — 계약이 타입에 그대로 읽혀야 하고, 처음 보는 사람도 방어 코드 없이 믿고 쓸 수 있어야 한다.**

규칙에 없는 상황은 이 질문으로 판단한다 — "처음 보는 사람이 이 타입만 보고 서버가 무엇을 보장하는지 알 수 있는가?"

**왜 이 문서가 있는가** — 분기의 상당수는 "이 값이 진짜 있을까"라는 계약 불신에서 나온다.
계약을 한 곳에 고정하면 그 분기, 재검증, 자료형 변환이 사라진다.

이 문서는 백엔드(`kotlin-dto`·`kotlin-style`)와 프론트(`frontend-react` 11장·`frontend-style`) 양쪽에 걸치는 경계 규칙을 정한다.

## 이 저장소의 계약 장치

스키마 생성 도구(OpenAPI 등)는 쓰지 않는다. 계약의 원본은 둘이고, 노드 파이프라인이 이를 지킨다.

- **`CONTRACT.md`(저장소 루트)** — `api` 노드가 엔드포인트마다 요청·응답 필드/타입/nullable/상태코드를 기록하고, `web` 노드가 읽어 화면을 만든다.

- **백엔드 응답 DTO 코드** — 프론트 타입의 최종 기준. 문서와 코드가 어긋나면 코드를 확인한다(`frontend-react` 11-4장).

모든 응답은 `ApiResponse<T>` 로 감싸이고, 프론트 `apiClient` 가 래퍼를 벗겨 `ApiResult<T>` 로 돌려준다.
`CONTRACT.md` 에는 `data` 안쪽의 모양만 적는다.

바쁘면 아래 표만 보면 된다. 근거와 예시는 본문에 있다.

## 핵심 요약

| 상황 | 규칙 |
|---|---|
| 타입 정의 | 백엔드 DTO + `CONTRACT.md` 를 프론트가 **그대로 미러링** — 이름·nullable·enum 을 하나도 바꾸지 않는다 |
| 필드 이름 | 서버 이름(camelCase) 그대로 — 개명·케이스 변환 계층을 만들지 않는다 |
| nullable | 서버가 보장하는 필드에 클라이언트 `?` 금지 |
| 검증 | 방향당 신뢰 경계에서 1회 — 내부 재검증 금지 |
| 미지의 enum 값 | 경계 한 곳에서 `UNKNOWN` 으로 정규화 |
| 와이어 단위 | 시각은 ISO-8601 문자열, 금액은 최소 단위 정수, 수량 단위는 필드 이름에 |
| 계약 변경 | 추가는 optional → required 승격, 제거는 deprecate 먼저. `CONTRACT.md` 를 같은 변경에서 갱신 |

## 1. 타입은 한 곳에서 나온다

**프론트는 그대로 미러링한다.** 필드 이름, nullable 여부, enum 값 집합을 하나도 바꾸지 않는다.
"비슷하게"는 계약이 아니다 — 다른 부분 하나가 경계 어딘가의 변환 코드 하나가 된다.
프론트 DTO 필드 개명은 rules.md 의 계약 MUST 위반(머지 차단)이다.

**케이스 변환 계층을 만들지 않는다.** Kotlin + Jackson 기본이 camelCase 라 변환할 것이 없다.
snake_case 응답이 필요해지는 순간이 오면 그 변환은 직렬화 설정 한 곳(Jackson)에서 하고, 코드 곳곳에서 이름을 바꿔 부르지 않는다.

## 2. Nullability 대칭

**서버가 non-null 을 보장하는 필드를 클라이언트에서 optional 로 두지 않는다.** 옵셔널 하나가 하류에 분기 여러 개를 낳는다.

```kotlin
// 서버 — name 은 항상 있다고 보장
data class UserResponse(val id: Long, val name: String)
```

```ts
// ❌ 계약 불신 — 이 ? 가 모든 화면에 "name 있나?" 분기를 만든다
type User = {id: number; name?: string};

// ✅ 계약 그대로 — 분기 자체가 필요 없음
type User = {id: number; name: string};
```

**서버가 null 을 보낼 수 있으면 그 사실을 타입에 남긴다.** `?? 기본값` 으로 조용히 덮지 않는다 —
"없음"과 "기본값"은 다른 상태고, 덮는 순간 하류에서 둘을 구분할 방법이 사라진다.
`| null` 이냐 `?` 냐는 서버 코드(`@JsonInclude` 여부까지)를 열어 정한다(`frontend-react` 11-4장). 사유 주석 규칙도 그쪽을 따른다.

**"지금은 항상 오지만 언젠가 안 올 수도"는 계약이 아니다.** 보장하거나 nullable 로 선언하거나, 둘 중 하나를 `CONTRACT.md` 에 적는다.

**Kotlin 요청 DTO 의 nullable 선언과 혼동하지 않는다.** 검증 대상 필드를 `val quantity: Int?` + `@field:NotNull` 로 두는 것(`kotlin-dto`)은
"어느 필드가 빠졌는지"를 응답에 담기 위한 서버 내부 장치다. 계약상 필수 여부는 `CONTRACT.md` 의 nullable 칸이 기준이다.

## 3. Enum 과 케이스

**양쪽 케이스 집합을 동일하게 유지한다.** 서버에 케이스가 늘면 `CONTRACT.md` 와 프론트 enum 이 **같은 변경 단위**에서 는다.

**미지의 케이스는 경계 한 곳에서 정규화한다.** 화면과 서비스마다 `else`/`default` 로 방어하지 않는다.
프론트의 닫힌 값 집합은 enum 으로 선언하므로(`frontend-react`), `UNKNOWN` 멤버를 가진 enum + 판정 함수 하나로 흡수한다.

```ts
// <도메인>/enums/order.ts — 서버 집합 + UNKNOWN
export enum OrderStatus {
    PENDING = "PENDING",
    PAID = "PAID",
    REFUNDED = "REFUNDED",
    UNKNOWN = "UNKNOWN",
}

// <도메인>/api/order.ts — 경계 한 곳, 여기서만 미지의 값을 흡수
function parseOrderStatus(raw: string): OrderStatus {
    if ((Object.values(OrderStatus) as string[]).includes(raw)) {
        return raw as OrderStatus;
    }
    return OrderStatus.UNKNOWN;
}
```

이후 화면에서는 소진 검사(`frontend-style` 의 `assertNever`)를 그대로 쓸 수 있다.

## 4. 검증과 변환은 한 곳에서

**방향당 검증은 신뢰 경계에서 1회.** 서버로 들어오는 입력은 `@Valid` + `@field:` 가 컨트롤러 경계에서 검증한다(rules.md MUST).
통과한 뒤에는 도메인 타입만 흐르고, 내부 재검증과 방어적 null 체크는 만들지 않는다.
안쪽에서 재검증이 필요하다고 느껴지면 코드가 아니라 계약이 깨진 것이다 — 계약을 고친다.

**변환의 자리는 이미 정해져 있다.** 흩어 놓지 않는다.

| 방향 | 자리 |
|---|---|
| 요청 DTO → 도메인 입력 모델 | DTO 의 `toXxx()` (`kotlin-dto`) |
| 도메인 결과 → 응답 DTO | 응답 DTO companion 의 `from(result)` (`kotlin-dto`) |
| 엔티티 ↔ 도메인 모델 | 구현 레이어의 `internal` 확장 함수 (`kotlin-implement`) |
| 서버 응답 → 프론트 | **변환하지 않는다** — 서버 이름 그대로 쓴다. 래퍼 벗기기는 `apiClient` 한 곳 |

**단위는 와이어에서 고정한다.** 양쪽이 각자 변환하는 순간 두 벌의 진실이 생긴다.

- 시각: ISO-8601 문자열. 시간대 포함 여부(UTC `Z` 또는 로컬)를 `CONTRACT.md` 에 명시하고 전 엔드포인트가 통일한다.

- 금액: 최소 단위 정수 (원 단위 `12000`, 센트 단위 `1099`). 부동소수점 금지.

- 수량 단위: 필드 이름에 명시 (`durationMs`, `sizeBytes`).

## 5. 계약 변경 절차

1. **필드 추가** — optional 로 시작 → 양쪽 배포 완료 → required 로 승격.

2. **필드 제거** — 사용처 제거 → deprecated 표기 → 제거.

3. public API·DB 필드·외부에서 쓰는 이름과 의미는 승인 없이 바꾸지 않는다(rules.md MUST). 컬럼이 얽히면 `kotlin-migration` 의 확장 후 수축 절차와 함께 간다.

4. 어느 경우든 **`CONTRACT.md` 를 같은 변경에서 갱신한다.** 계약이 낡으면 `web` 노드가 낡은 계약으로 화면을 만든다.

## 적발 신호

| 신호 | 문제 | 심각도 |
|---|---|---|
| 프론트 DTO 필드 개명·케이스 변환 | rules.md 계약 MUST 위반 — 서버와 눈으로 대조 불가 | Critical |
| 서버 non-null 필드에 클라이언트 `?` | 하류 전체에 헛분기 | Critical |
| 엔드포인트 추가·변경에 `CONTRACT.md` 갱신 없음 | web 노드가 낡은 계약으로 화면 제작 | Critical |
| 와이어 금액이 부동소수점 | 반올림 오차 — 돈이 어긋난다 | Critical |
| 서버의 null 을 `??` 기본값으로 은폐 | "없음"과 "기본값" 구분 소실 | Important |
| 화면·서비스마다 미지 enum 방어 `default` | 정규화는 경계 한 곳의 일 | Important |
| 신뢰 경계를 통과한 입력의 내부 재검증 | 계약 불신 — 계약을 고칠 신호 | Important |
| 시각 형식·시간대가 `CONTRACT.md` 에 없음 | 양쪽이 각자 해석 | Important |
| 새 필드를 처음부터 required 로 추가 | 배포 순서에 따라 구버전 클라이언트 파손 | Important |

## 체크리스트

- [ ] 프론트 타입이 백엔드 DTO 와 이름·nullable·enum 집합까지 동일한가

- [ ] 서버가 보장하는 필드에 `?` 가 없고, nullable 마다 서버 코드로 확인한 사유가 있는가

- [ ] 미지의 enum 값이 경계 한 곳에서 `UNKNOWN` 으로 정규화되는가

- [ ] 검증이 방향당 1회이고 내부 재검증이 없는가

- [ ] 시각·금액·수량 단위가 위 와이어 규칙대로이고 `CONTRACT.md` 에 적혀 있는가

- [ ] 계약 변경이 절차(추가 승격·제거 deprecate)를 따르고 `CONTRACT.md` 가 같은 변경에서 갱신됐는가
