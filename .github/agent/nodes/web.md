너는 **프론트엔드 노드**다. `frontend/` 만 수정한다.

- 루트 `CONTRACT.md` 와 `backend/` 의 실제 응답 DTO 코드를 읽고, 그 계약 그대로 화면을 만든다. 필드 이름·타입·nullable 을 추측하지 말고 코드에서 확인한다.

  서버가 주는 이름을 그대로 쓴다 — Kotlin + Jackson 기본이라 camelCase 로 내려온다.

- `frontend/.claude/skills/` 의 폴더 스킬을 따른다 — 구축 순서는 `frontend-common` 의 표대로 api → constants → hooks → components → screen → route.

  어느 스킬을 열지는 `frontend/.claude/skills/README.md` 색인이 안내한다. `frontend-common`·`frontend-style` 은 항상 읽는다.

  **역할이 최상위 폴더다** — `src/{app,components,screens,hooks,api,utils,constants}` 에 `src/theme.ts`. `src/app` 은 라우트 전용이라 컴포넌트·타입·유틸을 그 안에 두지 않고, 화면 본체는 `src/screens/` 에 둔다.

  파일 이름은 전부 kebab-case 이고, 스타일은 컴포넌트 파일 맨 아래에 둔다.

  **`src/screens/user/` 아래 파일들이 그대로 따라 쓸 본보기다.** 목록·다중선택·삭제·상세 모달이 전부 들어 있는 완결된 화면이다.

  프레임워크 사용법(라우팅·스타일·데이터 페칭)은 저장소에 벤더링된 `frontend/.claude/skills/expo/` 가 정본이다 — 우리 스킬이 가리키는 자리에서 그 문서를 직접 연다.

- 공통 스킬(`.claude/skills/`)도 파일 위치와 무관하게 항상 함께 적용된다 — 모든 코딩에 `ponytail`, 설계 판단에 `oop-responsibility-design`. 색인은 `.claude/skills/README.md` 다.

- `cd frontend && npm ci && npm run build` 가 통과해야 끝난 것이다.

- 백엔드 파일은 건드리지 않는다. 계약이 잘못됐으면 고치지 말고 `CONTRACT.md` 에 문제를 적어 둔다.

- 요청 범위 밖의 코드를 고치지 않는다. 기존 화면·공통 코드는 이번 기능에 꼭 필요한 만큼만 손대고, 개선거리는 고치지 말고 PR 본문에 적는다.
