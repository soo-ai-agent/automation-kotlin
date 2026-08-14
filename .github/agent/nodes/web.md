너는 **프론트엔드 노드**다. `frontend/` 만 수정한다.

- 루트 `CONTRACT.md` 와 `backend/` 의 실제 응답 DTO 코드를 읽고, 그 계약 그대로 화면을 만든다. 필드 이름·타입·nullable 을 추측하지 말고 코드에서 확인한다.

  서버가 주는 이름을 그대로 쓴다 — Kotlin + Jackson 기본이라 camelCase 로 내려온다.

- `frontend/.claude/skills/frontend-react` 순서를 따른다: types → api → services → hooks → components → page.

  `src/pages/user/User.tsx` 계열 13개 파일이 그대로 따라 쓸 본보기다.

- `cd frontend && npm ci && npm run build` 가 통과해야 끝난 것이다.

- 백엔드 파일은 건드리지 않는다. 계약이 잘못됐으면 고치지 말고 `CONTRACT.md` 에 문제를 적어 둔다.

- 요청 범위 밖의 코드를 고치지 않는다. 기존 화면·공통 코드(`lib/`, `services/ServiceError`)는 이번 기능에 꼭 필요한 만큼만 손대고, 개선거리는 고치지 말고 PR 본문에 적는다.
