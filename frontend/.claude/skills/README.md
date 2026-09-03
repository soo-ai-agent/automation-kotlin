# 프론트엔드 코딩 규칙 스킬

> **이 폴더는 에이전트가 읽습니다.** `frontend/` 아래 파일을 고칠 때 자동으로 적용됩니다.

Expo(React Native) + Expo Router + TypeScript 프론트엔드 규칙이다. 한 코드가 iOS·Android 네이티브와 웹(react-native-web)으로 나간다.

## 두 층으로 되어 있다

| 층 | 무엇 | 어디 |
|---|---|---|
| **프레임워크 규칙** | 폴더 구조·라우팅·스타일·데이터 페칭 — Expo 공식 문서 그대로 | [`expo/`](expo/README.md) (벤더링, 18종) |
| **저장소 규칙** | 의존 방향·화면 무상태·결과 표현·이름·리뷰 기준 | `frontend-*` (7종) |

**프레임워크 규칙을 `frontend-*` 에 베껴 쓰지 않는다.** 상위가 바뀔 때 한쪽만 고쳐지면 에이전트마다 다른 규칙을 본다(3대 원칙 제3원칙).

`expo/` 는 한 단계 깊어서 **Skill 도구로 부를 수 없다** — 목록에 이름조차 뜨지 않는다. 아래 스킬이 가리키는 자리에서 파일로 직접 연다.

이름만 알고 찾을 때는 [expo/README.md](expo/README.md) 가 18종을 전부 링크한다. 평평하게 올리지 않는 것은 벤더링 사본을 원문 그대로 두어 업그레이드 경로를 지키기 위해서다 — 대신 항상 실리는 설명 목록이 18종만큼 가벼워진다.

스택과 무관한 공통 규칙은 [`.claude/skills/`](../../../.claude/skills/) 에 있고, 프론트엔드 작업에도 항상 함께 적용된다.
최상위 원칙은 그중 `core-principles`(3대 원칙)다.

## 항상 읽는 둘

| 스킬 | 다루는 것 |
|---|---|
| [frontend-common](frontend-common/SKILL.md) | `src/` 폴더 지도·의존 방향, 파일 이름·export, 줄 길이, 이름, 구축 순서, 리뷰 절차 |
| [frontend-style](frontend-style/SKILL.md) | TS/RN 문법 — 판별 union·소진 검사, 조건부 렌더링, 리스트 key, 비동기 함정 |

## 화면 하나를 만들 때 — 아래에서 위로

| # | 스킬 | 폴더 |
|---|---|---|
| 1 | [frontend-api](frontend-api/SKILL.md) | `src/api/` · `src/constants/` — 서버 DTO 미러링, 엔드포인트 1:1 요청 함수, 상태코드 → 결과/`ServiceError` 번역 |
| 2 | [frontend-hooks](frontend-hooks/SKILL.md) | `src/hooks/` · `screens/<화면>/hooks/` — 단일책임 훅·조립 훅, 3상태, useEffect 판정 넷 |
| 3 | [frontend-screen](frontend-screen/SKILL.md) | `src/screens/` · `src/components/` — 화면 무상태, 모달 ref, 확인 팝업 |
| 4 | [frontend-route](frontend-route/SKILL.md) | `src/app/` — 라우트 파일이 하는 일 셋, 루트 레이아웃, 라우트 삭제 절차 |

## 상황에 따라

| 스킬 | 언제 |
|---|---|
| [frontend-e2e](frontend-e2e/SKILL.md) | Playwright 사용자 흐름 테스트 — `e2e` 노드 |
| [api-contract](../../../.claude/skills/api-contract/SKILL.md) (공통) | API 타입·DTO·필드를 추가·변경할 때 — 서버와의 계약 |
| [expo/](expo/README.md) | 라우팅·스타일·애니메이션·업그레이드 등 프레임워크 사용법 전반 |

## 끝났는지 확인

```bash
npm run lint && npm run e2e && npm run build
```

`lint` 는 포맷만이 아니라 React 훅·ref 규칙과 저장소 고유 규칙 둘(화면 무상태·HTTP 창구 하나)도 본다. `e2e` 를 `build` 보다 먼저 돌리는 것은 개발 서버가
라우트 타입(`.expo/types`)을 만들어야 `tsc` 가 `<Link href>` 오타를 잡기 때문이다. PR 에서도 같은 순서로 돈다.

## 핵심 다섯 줄

전문을 읽기 전에 이것만 알아도 절반은 맞는다.

- **`src/app` 은 라우트만 담는다.** 컴포넌트·타입·유틸을 그 안에 두지 않는다. 라우트 파일은 `screens/` 의 화면 하나를 그릴 뿐이다

- 참조는 `app → screens → components·hooks → api → utils → constants·theme` **한 방향**이다. 역방향·건너뛰기 금지

- **화면·컴포넌트에 `useState`/`useEffect` 를 두지 않는다.** 화면 상태는 전부 훅에 있고, 화면은 상태 훅 하나를 부르고 JSX 만 반환한다

- HTTP 상태코드 분기와 업무 규칙은 `src/api/` 의 요청 모듈에만 둔다. 훅은 상태코드를 모른다

- 예상된 비정상은 **결과 enum 반환**, 진짜 실패는 **`ServiceError` throw**. 불리언 반환 금지

## 파일 이름은 전부 kebab-case

Expo 기본 템플릿과 `expo-router` 규칙을 따른다 — `user-table.tsx`, `use-user-list.ts`, `format-date.ts`.
특수문자를 쓰지 않고, 라우트를 옮길 때는 옛 라우트 파일을 반드시 지운다.

## 정답 코드가 동봉되어 있다

글로 된 규칙과 코드가 어긋나면 **코드가 맞다.** 규칙을 그대로 구현해 `tsc --strict` 와 `expo export` 를 통과한 한 벌이 `frontend/src/` 에 살아 있다.

`src/screens/user/` 가 본보기다 — 목록·다중선택·삭제·상세 모달이 전부 들어 있는 완결된 화면이다.

## 문서 구조

스킬은 모두 같은 모양이다 — **규칙 → 적발 신호(`Critical` 은 머지 차단, `Important` 는 참고 코멘트) → 체크리스트.**

## 백엔드와의 계약

필드 이름은 **서버가 주는 이름 그대로** 쓴다. Kotlin + Jackson 기본이라 camelCase 로 내려온다 — 프론트에서 개명하면 머지가 막힌다.

기준은 루트 [CONTRACT.md](../../../CONTRACT.md) 와 백엔드 응답 DTO 코드다. 절차는 [api-contract](../../../.claude/skills/api-contract/SKILL.md).

머지를 막는 기준 전체는 [common/docs/code-review/rules.md](../../../common/docs/code-review/rules.md) 에 있다.
