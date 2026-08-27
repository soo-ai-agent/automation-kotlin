---
name: frontend-api
description: 서버와 통신하는 코드(src/api)의 저장소 고유 규칙. HTTP 창구 하나(api/client.ts)와 ApiResult 계약, 자원별 요청 모듈(api/<자원>.ts)의 엔드포인트 1:1 함수, 서버 DTO 미러링과 nullable 사유 주석, 상태코드를 결과 enum 또는 ServiceError 로 번역하는 2분법, 사용자 문장은 화면마다 한 파일인 constants/, 알림 단일 창구 notify, 401 단일 경로, 엔드포인트 차집합 대조를 담는다. fetch·캐싱·환경변수·토큰 보관은 벤더링된 expo/expo-data-fetching 이 정본이다. src/api/ 아래 파일을 만들거나 고치거나 리뷰할 때 frontend-common·api-contract 와 함께 사용한다. "API 호출 추가", "DTO 타입", "nullable", "에러 처리", "알림" 요청에도 사용할 것.
---

# 서버 통신 (src/api) — 계약의 사본과 결과 번역

서버와 말하는 코드는 전부 `src/api/` 에 있다. **자원마다 파일 하나**라 화면이 몇 개가 되든 폴더가 목차로 남는다. **React 를 모르는 순수 TS 모듈**이고, 훅만 이것을 부른다.

| 파일 | 하는 일 |
|---|---|
| `api/client.ts` | HTTP 창구 하나 — baseURL·응답 래퍼 벗기기 |
| `api/<자원>.ts` | 그 자원의 서버 DTO + 엔드포인트 1:1 요청 함수 + 상태코드 번역 |
| `constants/<화면>.ts` | 그 화면의 사용자 문장. `constants/index.ts` 가 재노출한다 |

**정본이 따로 있는 것들** — 여기 베껴 쓰지 않고 그때 연다.

| 알고 싶은 것 | 여는 문서 |
|---|---|
| `fetch` 사용법, 재시도·캐싱·오프라인, `EXPO_PUBLIC_` 환경변수, `expo-secure-store` 토큰 보관, React Query 도입 판단 | [expo/expo-data-fetching](../expo/expo-data-fetching/SKILL.md) |
| 서버·클라이언트 계약 대조 절차, 미지의 enum 정규화 | [api-contract](../../../../.claude/skills/api-contract/SKILL.md) (공통) |

이 문서는 그 위에 얹는 저장소 규칙만 담는다 — **ApiResult 계약, 2분법, 메시지·알림 창구.**

## HTTP 창구는 앱에 하나다

인증 헤더·baseURL·공통 응답 처리를 **`api/client.ts` 에서만** 설정한다. 두 번째 클라이언트를 만들면 인증과 에러 처리가 두 갈래로 갈라진다.

핵심 둘이다.

```ts
// 1) 비2xx 도 예외로 던지지 않고 상태코드를 그대로 넘긴다 — 판정은 요청 모듈의 몫이다.
// 2) 공통 응답 래퍼(ApiResponse)를 여기서 한 번 벗겨 낸다. 화면은 래퍼를 모른다.
export type ApiResult<T> =
    | {ok: true; status: number; data: T}
    | {ok: false; status: number};
```

`ApiResult<T>` 는 성공했을 때만 `data` 가 존재한다 — `result.ok` 를 확인하면 `data` 는 `T` 로 확정되므로
호출부에 null 검사가 필요 없다. "성공인데 데이터가 없는" 모순 상태를 타입이 막는다.

- **HTTP 라이브러리는 `expo/fetch` 다.** Expo 권장이고 네이티브·웹에서 같은 동작을 한다 — `axios` 를 새로 들이지 않는다.

- 인자는 **이름 있는 객체**(`{path, body}`)로 받는다. 위치 인자 `get(path, body, config)` 는 호출부에서 안 읽힌다.

- **`api/client.ts` 는 어떤 도메인 단어도 모른다.** 등장하면 그 자원의 요청 모듈로 옮긴다.

- 응답 래퍼 타입(`ApiResponseDTO<T>`)은 여기 한 번만 정의한다 — 서버 응답 모양이 바뀌면 고치는 곳은 이 타입 하나다.

- **Error 가 아닌 객체를 throw 하지 않는다.** `instanceof` 로 못 걸러지고 스택도 남지 않는다.

- **본문 없는 성공(204)도 성공이다.** `rules.md` MUST 가 "본문 없는 삭제 204" 를 요구하므로 클라이언트가 이걸 받아야 한다.
  빈 본문은 `data` 없는 성공으로, JSON 이 아닌 본문은 실패로 가른다 — 뒤엣것은 서버가 아니라 앞단(프록시)이 답한 경우다.

- **지금 있는 메서드는 `get`·`post`·`delete` 뿐이다.** 부분 수정(PATCH)처럼 없는 동사가 필요하면
  두 번째 클라이언트를 만들지 말고 **이 파일에 메서드를 더한다**(`HttpMethod` 멤버 1줄 + 메서드 3줄).
  쓰지도 않을 메서드를 미리 만들어 두지는 않는다.

### 주소와 비밀

이 저장소의 주소·키는 `app.json` 의 `extra` 에 있고 `utils/config.ts` 하나가 읽는다. 그 파일 밖에서 `Constants` 를 읽지 않는다.

`EXPO_PUBLIC_` 환경변수를 쓸 때의 규칙(빌드 시점에 번들에 박힌다, 비밀을 담지 않는다)과 토큰 보관(`expo-secure-store`)은
[expo/expo-data-fetching](../expo/expo-data-fetching/SKILL.md) 의 "Environment Variables"·"Authentication" 이 정본이다.

예시 값(이메일·토큰)을 기본값으로 코드에 박지 않는다. 없으면 빈 값으로 둔다.

## 요청 모듈 — 엔드포인트 1:1 + 결과 번역

`api/<자원>.ts` 하나가 그 자원의 DTO·요청 함수·상태코드 번역을 전부 갖는다.

```ts
// src/api/user.ts
const USERS = "/api/v1/users";

export interface User {
    id: number;
    name: string;
    phone?: string;       // 전화로 도움을 청할 수 있는 시설이 아니면 없음
}

export async function getUserList(): Promise<User[]> {
    const result: ApiResult<User[]> = await apiClient.get<User[]>({path: USERS});

    if (result.ok) {
        return result.data;
    }
    if (result.status === 401) {
        throw new ServiceError(SessionResultMessages.EXPIRED, 401, ErrorLevel.WARNING);
    }
    if (result.status === 403) {
        throw new ServiceError(UserResultMessages.FORBIDDEN, 403, ErrorLevel.WARNING);
    }
    throw new ServiceError(UserResultMessages.LIST_LOAD_ERROR, result.status, ErrorLevel.ERROR);
}
```

- **상태코드가 등장해도 되는 유일한 자리**가 이 모듈이다. 훅·컴포넌트에 `status === 404` 가 보이면 위반.

- 경로는 파일 상단 상수로 한 번만 쓴다. 함수마다 문자열을 반복하지 않는다.

- **경로에 동사를 넣지 않는다**(`rules.md` MUST). 여럿을 지울 때도 `POST /users/bulk-delete` 가 아니라
  `DELETE /users?ids=1,2` 다 — 대상은 질의 문자열로 고르고 행위는 HTTP 동사가 말한다.

- 요청 함수에 **반환 타입을 명시**한다. 추론에 맡기면 `undefined` 가 섞여 들어온다.

- 분기는 `if` 나열 + early return/throw. `switch` 중첩이나 삼항 사슬로 접지 않는다.

- 서버 DTO → 화면 모델 정규화(선택 필드를 빈 문자열·빈 배열로)도 여기서 **한 번만** 한다.

- **상태코드 번역 같은 짧은 분기 뭉치를 공용 헬퍼로 뽑지 않는다.** 각 함수가 자기 분기를 가진다 — 함수 하나가 위에서 아래로 완결되게.
  이 정도 중복은 허용하고, 분기가 진짜 커지면(검증 여러 개·부수 로직) 그때 내린다.

- 여기서 금지: JSX, `notify` 호출을 대신하는 화면 조작, 리다이렉트.

## 결과 enum vs ServiceError — 2분법

호출 결과를 **불리언이나 `null` 로 돌려주지 않는다.** 두 갈래 중 하나로 표현한다.

| 상황 | 표현 | 호출부 처리 |
|---|---|---|
| 예상된 비정상 (이미 삭제됨, 대상 없음 …) | **결과 enum 반환** | `if (outcome === X)` 로 분기, 안내 메시지 |
| 진짜 실패 (권한 없음, 서버 오류 …) | **`ServiceError` throw** | `catch` 에서 공용 핸들러 |

```ts
// O — 404 는 "실패"가 아니라 "이미 없음"이라는 결과다
export enum DeleteUserOutcome {
    SUCCESS         = "SUCCESS",
    ALREADY_MISSING = "ALREADY_MISSING",
}

export async function deleteUser(id: number): Promise<DeleteUserOutcome> {
    const result: ApiResult<void> = await apiClient.delete<void>({path: `${USERS}/${id}`});

    if (result.ok) {
        return DeleteUserOutcome.SUCCESS;
    }
    if (result.status === 404) {
        return DeleteUserOutcome.ALREADY_MISSING;
    }
    throw new ServiceError(UserResultMessages.DELETE_ERROR, result.status, ErrorLevel.ERROR);
}
```

`ServiceError`(`utils/service-error.ts`)는 **표시 수준(`ErrorLevel.WARNING/ERROR`)** 을 함께 들고 다닌다. 이것이 알림 종류를 결정한다.

**공용 에러 핸들러는 두 파일로 나눈다.** 한쪽에 몰면 통신 규칙이 React 에 묶인다.

| 파일 | 역할 | React |
|---|---|---|
| `utils/service-error-handler.ts` | 판정 전부 — 401 위임 / `level` 별 알림 / 폴백 로깅. 세션 만료 처리는 **콜백으로 주입** | 금지 |
| `hooks/use-service-error-handler.ts` | 얇은 래퍼 — React 의존 동작을 콜백으로 넘기고 `useCallback` 으로 안정화 | 허용 |

**401 은 이 경로 하나로만 처리한다.** 개별 훅이 각자 로그인 화면으로 보내면 안 된다.

## 닫힌 값 집합과 사용자 문장의 거처

폴더로 나누지 않는다. **소유자 옆에 둔다.**

| 무엇 | 어디 | 예 |
|---|---|---|
| 결과 enum (`*Outcome`) | 그 결과를 반환하는 요청 모듈 | `api/user.ts` |
| 상태 enum | 그 상태 타입을 소유한 파일 | `utils/list-state.ts` 의 `ListStatus` |
| 서버 DTO·요청 본문 | 그 자원의 요청 모듈 | `api/user.ts` |
| 화면 하나만 쓰는 타입·enum | 그 화면 폴더 안 | `screens/user/hooks/use-user-detail.ts` 의 `DetailStatus` |
| **사용자에게 보이는 문장** | **`constants/<화면>.ts`** | `constants/user.ts` 의 `UserResultMessages` |
| 색·간격·타이포 토큰 | `src/theme.ts` | `colors`, `spacing` |

**사용자 문장을 호출부에 흩뿌리지 않는다.** 메시지 enum 을 선언하고, 훅·컴포넌트는 그 멤버만 참조한다.

**파일은 화면·기능마다 하나다** — `constants/user.ts`, `constants/map.ts`. 한 파일에 몰면 화면이 늘 때마다 모두가 같은 파일을 건드려
머지 충돌이 상습이 되고, 선택 기능을 들어낼 때 남의 문장 사이에서 내 것만 골라내야 한다. 부르는 쪽은 언제나 `@/constants` 하나만 본다.

- 이름은 `<화면><용도>Messages`: `UserResultMessages`, `SessionResultMessages`.

- 멤버는 `UPPER_SNAKE_CASE`, 값은 완성된 한국어 문장(마침표 포함).

- 버튼 문구도 사용자 문장이다 — 화면마다 "확인"·"취소"를 적지 말고 공용 `ConfirmButtonLabel` 을 쓴다.

## 알림은 단일 창구

알림은 `notify.*`(`utils/notify.ts`) 하나로만 부른다. 알림 UI 를 아는 유일한 파일이라,
토스트·스낵바로 바꿀 때 고치는 파일이 이 하나뿐이고 호출부는 한 줄도 손대지 않는다 — 그것이 이 창구를 두는 이유다.

- 컴포넌트·훅이 알림 라이브러리(`Alert.alert`·`window.alert` 등)를 직접 부르면 위반. 플랫폼 분기도 notify 안에서 끝난다.

- **확인은 OS 대화상자가 아니라 앱 디자인 팝업으로 묻는다.** 창구는 똑같이 `notify.confirm` 이고 `Promise<boolean>` 을 돌려준다.
  되돌릴 수 없는 동작(삭제·종료)에만 `destructive: true` — 확인 버튼이 위험색으로 바뀐다. (그리는 구조는 `frontend-screen` 의 전역 확인 팝업 절)

- **폴백은 화면을 유지하는 수단이지 실패를 숨기는 수단이 아니다.** 데이터 로드 실패로 폴백을 그릴 때는 반드시 `notify` 로 알린다(세션당 1회로 반복 억제 가능).
  조용한 폴백은 사용자가 빠진 데이터를 정상으로 믿게 만든다.

## 서버 DTO 는 서버가 주는 그대로

**필드 이름을 프론트에서 개명하지 않는다.** 기준은 루트 `CONTRACT.md` 와 백엔드 응답 DTO 코드다. 대조 절차는 `api-contract` 가 담당한다.

### `?` 는 서버 코드를 열어 정한다

`?`·`| null` 을 습관으로 붙이지 않는다. 서버 응답 타입을 열어 **정말 빠질 수 있는 값인지** 확인하고, 그 자리에 사유를 적는다.

```ts
// O — 왜 없을 수 있는지가 그 줄에 있다
phone?: string;       // 전화로 도움을 청할 수 있는 시설이 아니면 없음
```

같은 문장이 여러 줄 반복되면 주석을 줄일 게 아니라 **`?` 를 줄일 자리다** — 함께 비는 값이면 전용 타입 한 덩이로 묶어 그 덩이 하나를 `?` 로 만든다.
예외는 와이어 DTO 하나 — 서버가 평평하게 보내는 응답은 묶으면 모양이 거짓이 된다. 이때만 타입 위에 한 번 적되, 서버 코드 어디를 봤는지 근거를 함께 적는다.

### 타입 규칙

- `any` 금지. `unknown` 도 최소화 — 모양을 정말 보장할 수 없는 자리(catch 예외, 직렬화 경계)에서만 쓰고,
  "왜 모를 수밖에 없는지" 주석을 달아 경계에서 즉시 좁힌다.

- **지역 변수에도 타입을 적는다**: `const res: ApiResult<void> = await deleteUser(id);`

- `object`·`{}`·`Record<string, unknown>` 을 도메인 데이터에 쓰지 않는다. 필드를 아는 데이터는 필드를 적는다.

- `props` 는 항상 명시적 `type`/`interface`. 훅 파라미터가 2개를 넘으면 이름 있는 객체(`UseXxxParams`)로 받는다.

### 이름을 되풀이하는 주석은 지운다

기본은 무주석이다. 주석은 **코드가 말할 수 없는 것**만 적는다 — 왜 없을 수 있는지, 외부 규격, 단위·범위, 의도한 규칙 이탈.

```ts
// X — 지운다. 이름과 타입이 이미 말한다
/** 소요 ms. */  durationMs: number;

// O — 남긴다. 코드가 말할 수 없는 것이다
/** 0~1. */      successRate: number;
```

이름만 되풀이하는데 그 줄에 `?` 가 있으면, 지우지 말고 **`?` 사유로 바꿔 쓴다.**

## 엔드포인트도 대조한다

프론트가 부르는 경로가 서버에 없으면 그 화면은 영원히 404 다. 타입만 맞추지 말고 **경로도 맞춘다.**

```
서버:  컨트롤러의 @RequestMapping + @GetMapping/@PostMapping 을 모아 목록으로
프론트: api/*.ts 의 경로 상수를 모아 목록으로          →  차집합이 0 이어야 한다
```

없는 경로를 부르는 화면을 발견하면 **조용히 폴백을 넣지 말고** 보고한다 — 화면을 지울지 서버를 만들지는 사람이 정한다.

## 적발 신호

| 신호 | 문제 | 심각도 |
|---|---|---|
| 두 번째 HTTP 클라이언트 신설 | 인증·에러 처리가 두 갈래로 갈라진다 | Critical |
| 훅·컴포넌트·화면의 `result.status ===` 분기 | 상태코드 번역은 요청 모듈 전담 | Critical |
| `utils/` 통신 파일에 React import | 계층 붕괴 — 이 층은 React 를 모른다 | Critical |
| `window.alert`/`confirm`/`Alert.alert` 직접 호출 | 알림 단일 창구(`notify`) 위반 | Critical |
| 알림 없는 조용한 폴백 | 고장이 정상으로 보인다 | Critical |
| 서버 코드를 안 보고 붙인 DTO `?` ("누락 시 0" 주석) | 계약이 둘로 쪼개진다 | Critical |
| 서버에 없는 엔드포인트를 부르는 화면 | 영원히 404 | Critical |
| 사유 주석 없는 `?` 선언 | 안 오는 값인지 안 줘도 되는 값인지 못 읽는다 | Critical |
| DTO 필드를 서버 응답과 다른 이름으로 개명 | `CONTRACT.md` 와 눈 대조 불가 | Critical |
| `any`, 습관적 `?`, `Record<string, unknown>`, 사유 없는 `unknown` | 자료형 뭉개기 | Critical |
| `EXPO_PUBLIC_` 환경변수에 담긴 비밀 | 번들에 그대로 박힌다 | Critical |
| 결과를 boolean·문자열·`null` 로 반환 | 2분법 위반 | Important |
| 사용자 문장 인라인 문자열 | `constants/` 위반 | Important |
| 새 화면 문장을 기존 `constants/` 파일에 얹음 | 화면·기능당 한 파일 — 머지 충돌 | Important |
| 개별 훅의 자체 401 처리 | 세션 만료 경로 이원화 | Important |
| 요청 함수 반환 타입 미선언 | `undefined` 가 추론에 섞여 들어온다 | Important |
| 상태코드 번역 분기를 공용 헬퍼로 추출 | 함수 완결성 훼손 — 이 중복은 허용 | Important |
| 위치 인자로 늘어선 클라이언트 시그니처 | 호출부에서 안 읽힌다 — 이름 있는 객체로 | Important |
| Error 가 아닌 평범한 객체 throw | `instanceof` 로 못 걸러지고 스택도 없다 | Important |
| 이름을 되풀이할 뿐인 주석 | 정보 0, 이름 바뀌면 거짓말 | Important |

## 체크리스트

- [ ] HTTP 클라이언트가 `api/client.ts` 하나뿐이고, 통신 파일에 React 가 없는가

- [ ] 상태코드 분기가 요청 모듈에만 있는가

- [ ] 예상된 비정상은 결과 enum, 진짜 실패는 `ServiceError` throw 인가

- [ ] 사용자 문장이 `constants/<화면>.ts` 에 있고, 알림이 `notify` 경유인가

- [ ] 401 이 공용 핸들러 한 경로로만 처리되는가

- [ ] DTO 필드명이 서버 그대로이고, `?` 마다 사유가 그 자리에 있는가

- [ ] 부르는 엔드포인트가 서버 매핑에 전부 있는가
