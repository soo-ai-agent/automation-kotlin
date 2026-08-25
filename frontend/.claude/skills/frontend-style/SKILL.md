---
name: frontend-style
description: TypeScript React Native 의 조건·분기·반복·비동기 문법 규칙. 판별 union 상태 표현과 switch 소진 검사, JSX 조건부 렌더링(숫자 && 금지), ??/|| 구분, 훅 호출 위치, 리스트 key, 배열 원본 보존, catch 의 unknown 좁히기, 떠 있는 Promise 를 다룬다. .tsx/.ts 에서 조건부 렌더링·훅 조건·리스트 key·async 오류를 작성하거나 리뷰할 때 frontend-common 과 항상 함께 사용한다. "조건부 렌더링", "리스트 key", "훅 조건" 요청에도 사용할 것.
---

# TypeScript/RN 문법: 조건·반복·비동기

**원칙 — 코드에 의도와 로직이 그대로 읽혀야 하고, 처음 보는 사람도 설명 없이 이해할 수 있어야 한다.**

아래 규칙은 전부 이 원칙의 적용이다: 유효한 상태만 표현 가능하게 만들고, 렌더링 조건을 명시적 불리언으로 쓰고, 케이스 누락을 컴파일러가 잡게 한다.

규칙에 없는 상황은 이 질문으로 판단한다 — "처음 보는 사람이 이 조건과 흐름을 설명 없이 따라갈 수 있는가?"

**다루는 것** — 분기·반복·비동기에서 TS/RN 문법 때문에 달라지는 규칙.

**다루지 않는 것** — 폴더·계층·람다 기준은 `frontend-common` 에, 페이지 무상태는 `frontend-screen` 에, 결과 표현(2분법)은 `frontend-service` 에,
타입·DTO 규칙은 `frontend-api` 에, 서버-클라이언트 계약은 `api-contract` 에, 언어 무관 규칙은 공통 스킬(`.claude/skills/`)에 있다.

이 스킬은 레이어 스킬들의 문법 보강이다. 충돌하면 레이어 스킬과 동봉 정답 코드(`frontend/src/`)가 우선한다.

`kotlin-style`·`api-contract` 와 목표(유지보수성·정합성·가독성)를 공유한다 — 전문은 `api-contract` 의 "세 스킬이 공유하는 목표" 절.

바쁘면 아래 표만 보면 된다. 근거와 예시는 본문에 있다.

## 핵심 요약

| 상황 | 규칙 |
|---|---|
| 상태 표현 | 새 다갈래 상태는 판별 필드(enum) union — `loading`·`data`·`error` 를 나란히 두지 않는다 |
| 상태 분기 | `switch` + `assertNever` 소진 검사 |
| 조건부 렌더링 | `{count && ...}` 금지 — 명시적 불리언으로 |
| 기본값 | `\|\|` 대신 `??` |
| 훅 호출 | 조건·루프·early return 뒤에서 금지 |
| 리스트 key | 배열 인덱스 금지 — 안정적인 도메인 id |
| 배열 변형 | `sort`·`reverse`·`splice` 는 복사본에서 |
| `catch (e)` | `e` 는 `unknown` — 좁히기 전에 읽지 않는다 |

## 1. 상태를 먼저 올바르게 표현한다

**여러 갈래 상태를 새로 설계할 때는 판별 필드를 가진 union 으로 표현한다.** `loading`·`data`·`error` 를 나란히 두면
"로딩 중인데 에러도 있음" 같은 조합이 표현 가능해지고, 그 조합을 막느라 화면마다 방어 분기가 생긴다.

판별 필드의 값 집합은 문자열 리터럴이 아니라 **enum** 으로 선언한다(`frontend-api` 의 enum 규칙). 선언 자리는 `enums/` 다.

```ts
// ❌ 8가지 조합 중 3가지만 유효 — 나머지는 화면이 방어해야 함
type DetailState = {loading: boolean; data?: User; error?: string};

// ✅ 유효한 상태만 표현 가능
export enum DetailStatus {
    LOADING = "LOADING",
    READY = "READY",
    FAILED = "FAILED",
}

type DetailState =
    | {status: DetailStatus.LOADING}
    | {status: DetailStatus.READY; data: User}
    | {status: DetailStatus.FAILED; message: string};
```

공용 3상태 목록 표현형은 이미 있다 — `common/lib/listState.ts`(`ListStatus.OK/EMPTY/ERROR` — `frontend-hooks` 의 3상태 절). 목록 화면은 그것을 그대로 쓰고,
이 규칙은 도메인 고유의 다갈래 상태를 **새로** 만들 때 적용한다.

**`field?:` 와 `field: T | undefined` 를 구분한다.** 앞은 "필드 자체가 없을 수 있다", 뒤는 "필드는 있으나 값이 비어 있을 수 있다"이다.
계약이 다르면 타입도 달라야 한다. `?` 마다 사유 주석, `x?: T | null` 의 판정 기준은 `frontend-api` 가 담당한다.

**배열 인덱싱은 `noUncheckedIndexedAccess` 없이는 거짓말을 한다.** 이 저장소 tsconfig 에는 꺼져 있으므로,
인덱스 접근 뒤 존재 확인을 직접 한다(`items[i]` 를 바로 쓰지 않고 지역 변수에 받아 `undefined` 를 판정).

## 2. 분기

**union 은 `switch` 로 다루고 default 에서 소진 검사를 한다.** 새 케이스가 생기면 컴파일이 깨져서, 처리 누락이 리뷰가 아니라 빌드에서 잡힌다.
(백엔드 `kotlin-style` 의 "else 없는 when" 과 짝이 되는 규칙이다.)

```tsx
function assertNever(x: never): never {
    throw new Error(`Unhandled case: ${JSON.stringify(x)}`);
}

switch (state.status) {
    case DetailStatus.LOADING: return <Spinner />;
    case DetailStatus.READY:   return <Profile user={state.data} />;
    case DetailStatus.FAILED:  return <ErrorView message={state.message} />;
    default:                   return assertNever(state);
}
```

**숫자가 될 수 있는 값으로 `&&` 렌더링을 하지 않는다.**

```tsx
// ❌ count 가 0 이면 화면에 "0" 이 그려지고, RN 에서는 <Text> 밖 텍스트라 크래시까지 남
{count && <Badge count={count} />}

// ✅ 명시적 불리언
{count > 0 && <Badge count={count} />}
```

**기본값에는 `??` 를 쓴다.** `||` 는 `0`, `''`, `false` 를 "없음"으로 취급한다.

```ts
const qty = input.qty || 1;  // ❌ 0개 주문이 1개로 둔갑
const qty = input.qty ?? 1;  // ✅ null/undefined 일 때만 1
```

서버가 보낼 수 있는 `null` 을 `??` 로 조용히 덮지 않는다 — 그 판단은 `api-contract` 의 nullability 규칙을 따른다.

**JSX 안 삼항 중첩은 금지한다.** 두 갈래를 넘으면 컴포넌트 위쪽에서 early return 하거나 렌더 함수를 나눈다.

**옵셔널 체이닝의 결과는 `undefined` 다.** `a?.b === false`(a 가 없으면 false)와 `!a?.b`(a 가 없으면 true)는 다른 판단이다.
셋 중 무엇을 묻는지 — 없음 / false / 둘 다 — 코드에 드러나야 한다.

**훅은 조건, 루프, early return 뒤에서 호출하지 않는다.** 호출 순서가 곧 훅의 정체성이라, 분기 하나가 상태 전체를 어긋나게 한다.

## 3. 반복과 리스트

**리스트 key 는 안정적인 도메인 id 를 쓴다.**

```tsx
// ❌ 재정렬·삭제 시 입력값과 체크 상태가 엉뚱한 행에 남음
{items.map((item, i) => <Row key={i} item={item} />)}

// ✅
{items.map(item => <Row key={item.id} item={item} />)}
```

**배열 변형은 새 배열을 만든다.** `sort`·`reverse`·`splice` 는 원본을 바꿔, 같은 배열을 보던 다른 곳의 전제를 오염시킨다.

```ts
const sorted = [...items].sort(byDate);  // ✅ 원본 보존
```

판단·누적이 든 람다 체이닝을 풀어 쓰는 기준과 허용 관용구(훅 인자·JSX 핸들러·`keyExtractor` 등)는 `frontend-common` 이 담당한다.

## 4. 비동기와 예외 — 잡는 쪽 문법

**결과 표현은 `frontend-service` 의 2분법이 기준이다.** 예상된 비정상은 결과 enum 반환, 진짜 실패는 `ServiceError` throw —
상태코드 번역은 services 가 하고, 훅은 `useServiceErrorHandler` 로 받는다. 이 절은 그 위에서의 문법만 다룬다.

**`try`/`catch` 는 실제 `await` 경계에만 둔다.** 순수 계산까지 감싸면 버그가 "네트워크 오류" 메시지로 둔갑한다.

**`catch (e)` 의 `e` 는 `unknown` 이다.** 좁히기 전에 `e.message` 를 읽지 않는다 (`unknown` 사유·즉시 좁히기 규칙은 `frontend-api`).

```ts
catch (e) {
    const message = e instanceof Error ? e.message : String(e);
}
```

**Error Boundary 는 렌더 중 에러만 잡는다.** 이벤트 핸들러와 비동기 실패는 직접 처리해야 한다.

**`Promise` 를 만들고 `await` 하지 않으면 실패가 조용히 사라진다.** 의도적이라면 `void save();` 처럼 의도를 표기한다.

## 적발 신호

| 신호 | 문제 | 심각도 |
|---|---|---|
| `{count && <A />}` 등 숫자가 될 수 있는 값의 `&&` 렌더링 | 0 이 그려지고, RN 은 `<Text>` 밖 텍스트로 크래시 | Critical |
| 기본값에 `\|\|` 사용 | `0`·`''`·`false` 가 없음으로 둔갑 | Critical |
| 조건·루프·early return 뒤의 훅 호출 | 훅 순서 붕괴 — 상태 전체가 어긋남 | Critical |
| `await` 없는 Promise 방치 (`void` 표기 없음) | 실패가 조용히 사라짐 | Critical |
| `loading`·`data`·`error` 를 나란히 둔 새 상태 타입 | 불가능한 조합을 화면마다 방어 | Important |
| 판별 union 분기에 소진 검사(`assertNever`) 없음 | 새 케이스 누락이 조용히 통과 | Important |
| `key={index}` | 재정렬·삭제 시 상태 꼬임 | Important |
| `sort`·`reverse`·`splice` 로 원본 배열 변형 | 같은 배열을 보는 곳의 전제 오염 | Important |
| 좁히기 전의 `e.message` 접근 | `e` 는 `unknown` — 런타임 오류 | Important |
| JSX 안 삼항 중첩 | 렌더 분기 은폐 | Important |

## 체크리스트

- [ ] 새 다갈래 상태가 판별 필드(enum) union 인가 — 불가능한 조합이 표현 불가능한가

- [ ] union 분기에 `assertNever` 소진 검사가 있는가

- [ ] 조건부 렌더링이 명시적 불리언인가 (`{숫자 && ...}` 가 없는가)

- [ ] 기본값이 `??` 인가

- [ ] 훅이 컴포넌트 최상위에서만 불리는가

- [ ] 리스트 key 가 도메인 id 인가, 배열 변형이 복사본에서 일어나는가

- [ ] `catch` 의 `e` 를 좁혀 쓰고, 떠 있는 Promise 에 `void` 표기가 있는가
