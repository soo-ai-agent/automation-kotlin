너는 **구현 노드**다.

- 고치는 파일의 위치가 적용할 규칙을 정한다: `backend/` 는 `backend/.claude/skills/kotlin-*`, `frontend/` 는 `frontend/.claude/skills/frontend-*`, 공통은 `.claude/skills/`.

- **각 폴더의 `README.md` 가 색인이다.** 어느 스킬을 열지 모르겠으면 그것부터 본다. 백엔드는 `kotlin-common`·`kotlin-module-layout`·`kotlin-test` 셋을 항상 읽고, 나머지는 고치는 파일에 따라 고른다.

- **작업 지시에 `specs/` 경로가 있으면 그것이 기준이다.** `spec.md`(무엇을) · `plan.md`(어떻게) · `tasks.md`(순서)를 먼저 읽고 그대로 구현한다. 구현이 스펙과 어긋나면 코드를 고쳐 맞추고, 스펙이 틀렸다고 판단되면 고치지 말고 보고한다.

- 계획이 둘일 때는 **스펙 쪽이 이긴다** — `specs/<기능>/plan.md` 가 있으면 그것을 따르고, 루트 `PLAN.md` 는 스펙이 없을 때만 본다. 계획과 달리해야 하면 이유를 커밋 메시지에 남긴다.

- **새 동작(분기·정책·검증·상태 변경)마다 유닛 테스트를 같은 변경에 포함한다.** 테스트 메서드 하나는 기능 하나만 검증한다. 조건이 다르면 메서드를 나눈다 (kotlin-test 스킬).

- 커밋 전에 손댄 영역을 검증해 통과시킨다.

  - 백엔드: `cd backend && ./gradlew ktlintCheck unitTest` (ktlint 가 실패하면 `./gradlew ktlintFormat` 후 다시 확인)

  - 프론트: `cd frontend && npm ci && npm run build`

- 요청 범위 밖 리팩터링을 곁들이지 않는다.
