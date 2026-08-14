# 프론트엔드 코딩 규칙 스킬

> **이 폴더는 에이전트가 읽습니다.** `frontend/` 아래 파일을 고칠 때 자동으로 적용됩니다.

React + TypeScript 프론트엔드 규칙과 E2E 테스트 규칙이다. 스택과 무관한 공통 규칙은 [`.claude/skills/`](../../../.claude/skills/) 에 있다.

| 파일 | 무엇이 들어 있나 | 언제 |
|---|---|---|
| [frontend-react/SKILL.md](frontend-react/SKILL.md) | 규칙 요약 — 코드 스타일, 적발 신호, 체크리스트 | 프론트 작업·리뷰 전부 |
| [frontend-react/chapters.md](frontend-react/chapters.md) | 0~16장 전문과 ❌/✅ 사례 | SKILL.md 만으로 판단이 안 설 때 해당 장만 |
| [frontend-e2e/SKILL.md](frontend-e2e/SKILL.md) | Playwright E2E — 선택자 정책, 대기, 다이얼로그 함정 | `e2e` 노드, 사용자 흐름 테스트 |

## 핵심 다섯 줄

전문을 읽기 전에 이것만 알아도 절반은 맞는다.

- 참조는 `pages → hooks → services → api → lib` **한 방향**이다. 역방향·건너뛰기 금지

- **페이지·컴포넌트에 `useState`/`useEffect` 를 두지 않는다.** 화면 상태는 전부 훅에 있고, 페이지는 훅 하나를 부르고 JSX 만 반환한다

- HTTP 상태코드 분기와 업무 규칙은 `services/` 에만 둔다. 훅은 상태코드를 모른다

- 예상된 비정상은 **결과 enum 반환**, 진짜 실패는 **`ServiceError` throw**. 불리언 반환 금지

- 사용자에게 보이는 문장은 전부 `enums/` 의 메시지 enum 에, 알림은 `lib/notify.ts` 한 창구로

## 정답 코드가 동봉되어 있다

글로 된 규칙과 코드가 어긋나면 **코드가 맞다.** 규칙을 그대로 구현해 `tsc --strict` 를 통과한 한 벌이 `frontend/src/` 에 살아 있다.

`src/pages/user/User.tsx` 의 사용자 목록 화면이 본보기다 — 목록·다중선택·삭제·상세 모달이 전부 들어 있는 완결된 슬라이스다.

새 화면은 user 도메인 파일 13개를 복사해 이름만 바꾸는 것으로 시작한다. 순서는 types → api → services → hooks → components → page.

## 백엔드와의 계약

필드 이름은 **서버가 주는 이름 그대로** 쓴다. Kotlin + Jackson 기본이라 camelCase 로 내려온다 — 프론트에서 개명하면 머지가 막힌다.

기준은 루트 [CONTRACT.md](../../../CONTRACT.md) 와 백엔드 응답 DTO 코드다.

머지를 막는 기준 전체는 [common/docs/code-review/rules.md](../../../common/docs/code-review/rules.md) 에 있다.
