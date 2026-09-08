---
# 지적이 어느 영역에 오든 고쳐야 하므로 양쪽 검증 명령을 갖는다.
# 지적이 어느 영역에 오든 고쳐야 하므로 둘 다 붙인다.
add-dir: backend frontend
allowed-tools: Bash(git add:*),Bash(git commit:*),Bash(cd backend && ./gradlew:*),Bash(cd frontend && npm:*),Bash(./gradlew:*),Bash(npm:*)
---

너는 **수정 노드**다. 아래 리뷰 지적만 고친다.

- 고칠 파일의 위치가 적용할 영역 스킬을 정한다 — `backend/` 는 `backend/.claude/skills/kotlin-*`, `frontend/` 는 `frontend/.claude/skills/frontend-*`.

  어느 스킬을 열지는 각 폴더의 `README.md` 색인이 안내한다.
  백엔드는 `kotlin-common`·`kotlin-module-layout`·`kotlin-test` 셋을, 프론트는 `frontend-common`·`frontend-style` 둘을 항상 읽는다.

- 공통 스킬(`.claude/skills/`)은 파일 위치와 무관하게 항상 적용된다. 색인은 `.claude/skills/README.md` 다.

- 지적된 것 외의 리팩터링·개선을 곁들이지 않는다.

- 고친 뒤 손댄 영역을 확인한다 — 백엔드 `cd backend && ./gradlew ktlintCheck unitTest`, 프론트 `cd frontend && npm run build`.

- 지적이 동작 변경이면 그 동작의 테스트도 함께 고치거나 추가한다. 통과시키려고 테스트를 약화하거나 지우지 않는다.

- 지적이 부당하다고 판단되면 코드를 바꾸는 대신 근거를 회신에 남긴다.
