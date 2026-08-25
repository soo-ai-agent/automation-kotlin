# 프론트엔드 코딩 규칙 스킬

> **이 폴더는 에이전트가 읽습니다.** `frontend/` 아래 파일을 고칠 때 자동으로 적용됩니다.

React Native(Expo) + TypeScript 프론트엔드 규칙이다. 한 코드가 iOS·Android 네이티브와 웹(react-native-web)으로 나간다.

스택과 무관한 공통 규칙은 [`.claude/skills/`](../../../.claude/skills/) 에 있고, 프론트엔드 작업에도 항상 함께 적용된다.

**8종을 다 읽지 않는다.** 아래 "항상" 둘을 읽고, 나머지는 지금 고치는 파일의 레이어에 따라 골라 읽는다.

## 항상

| 스킬 | 다루는 것 |
|---|---|
| [frontend-common](frontend-common/SKILL.md) | 도메인 최상위 폴더·의존 방향, 파일 이름·export, 줄 길이, 람다 관용구, 이름, 구축 순서, 리뷰 절차 |
| [frontend-style](frontend-style/SKILL.md) | TS/RN 문법 — 판별 union·소진 검사, 조건부 렌더링, 리스트 key, 비동기 함정 |

## 화면 하나를 만들 때 — 아래에서 위로

새 화면은 이 순서로 만든다 (`frontend-common` 의 구축 순서 표). `src/user/` 가 그대로 따라 쓸 본보기다.

| # | 스킬 | 레이어 |
|---|---|---|
| 1 | [frontend-api](frontend-api/SKILL.md) | `types/` + `api/` — 서버 DTO 미러링, 엔드포인트 1:1, nullable 판정 |
| 2 | [frontend-service](frontend-service/SKILL.md) | `services/` + `enums/` — 상태코드 → 결과 enum/`ServiceError` 번역, 메시지 enum, notify |
| 3 | [frontend-hooks](frontend-hooks/SKILL.md) | `hooks/` — 단일책임 훅·조립 훅, 3상태, useEffect 판정 넷 |
| 4 | [frontend-screen](frontend-screen/SKILL.md) | `screens/` + `components/` — 페이지 무상태, 모달 ref, 확인 팝업, 스타일 분리 |

## 상황에 따라

| 스킬 | 언제 |
|---|---|
| [frontend-lib](frontend-lib/SKILL.md) | `lib/` 를 만지거나 공통 창구(HTTP 클라이언트·notify)를 바꿀 때 |
| [frontend-e2e](frontend-e2e/SKILL.md) | Playwright 사용자 흐름 테스트 — `e2e` 노드 |
| [api-contract](../../../.claude/skills/api-contract/SKILL.md) (공통) | API 타입·DTO·필드를 추가·변경할 때 — 서버와의 계약 |

## 핵심 다섯 줄

전문을 읽기 전에 이것만 알아도 절반은 맞는다.

- 참조는 `screens → hooks → services → api → lib` **한 방향**이다. 역방향·건너뛰기 금지

- **화면·컴포넌트에 `useState`/`useEffect` 를 두지 않는다.** 화면 상태는 전부 훅에 있고, 화면은 훅 하나를 부르고 JSX 만 반환한다

- HTTP 상태코드 분기와 업무 규칙은 `services/` 에만 둔다. 훅은 상태코드를 모른다

- 예상된 비정상은 **결과 enum 반환**, 진짜 실패는 **`ServiceError` throw**. 불리언 반환 금지

- 사용자에게 보이는 문장은 전부 `enums/` 의 메시지 enum 에, 알림은 `common/lib/notify.ts` 한 창구로

## 정답 코드가 동봉되어 있다

글로 된 규칙과 코드가 어긋나면 **코드가 맞다.** 규칙을 그대로 구현해 `tsc --strict` 를 통과한 한 벌이 `frontend/src/` 에 살아 있다.

`src/user/screens/User.tsx` 의 사용자 목록 화면이 본보기다 — 목록·다중선택·삭제·상세 모달이 전부 들어 있는 완결된 슬라이스다.

## 문서 구조

스킬은 모두 같은 모양이다 — **규칙 → 적발 신호(`Critical` 은 머지 차단, `Important` 는 참고 코멘트) → 체크리스트.**

## 백엔드와의 계약

필드 이름은 **서버가 주는 이름 그대로** 쓴다. Kotlin + Jackson 기본이라 camelCase 로 내려온다 — 프론트에서 개명하면 머지가 막힌다.

기준은 루트 [CONTRACT.md](../../../CONTRACT.md) 와 백엔드 응답 DTO 코드다. 절차는 [api-contract](../../../.claude/skills/api-contract/SKILL.md).

머지를 막는 기준 전체는 [common/docs/code-review/rules.md](../../../common/docs/code-review/rules.md) 에 있다.
