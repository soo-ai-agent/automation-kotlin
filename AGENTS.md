# Codex 작업 규칙

> **이 문서는 에이전트가 읽습니다.** 사용자가 읽을 문서는 [README.md](README.md) 입니다.

규칙의 단일 출처는 스킬이다 — 공통 `.claude/skills/`, 백엔드 `backend/.claude/skills/`, 프론트엔드 `frontend/.claude/skills/`. Claude 는 자동으로 읽고, Codex 는 아래 표를 보고 직접 읽는다.

규칙을 고칠 때는 스킬 파일만 고친다 — 두 에이전트가 다른 규칙을 보면 안 된다.

## 작업 전 필독 (작업 영역별)

| 작업 | 읽을 파일 |
|---|---|
| 모든 코딩 | `.claude/skills/ponytail/SKILL.md` |
| 설계 판단 (책임 배치·다형성·상속) | `.claude/skills/oop-responsibility-design/SKILL.md` |
| 백엔드 공통 | `backend/.claude/skills/kotlin-common/SKILL.md` |
| 파일을 어디 둘지 판단 | `backend/.claude/skills/kotlin-module-layout/SKILL.md` |
| 엔드포인트 추가 | `backend/.claude/skills/kotlin-controller`, `kotlin-dto` |
| 업무 흐름·트랜잭션 | `backend/.claude/skills/kotlin-domain-service` |
| 조회·저장 상세 구현 | `backend/.claude/skills/kotlin-implement` |
| 테이블·상태 변경 | `backend/.claude/skills/kotlin-entity` |
| 쿼리 | `backend/.claude/skills/kotlin-repository` |
| 테스트 (모든 기능 작업에 동반) | `backend/.claude/skills/kotlin-test` |
| 프론트엔드 | `frontend/.claude/skills/frontend-react/SKILL.md` + `chapters.md` 해당 장, `frontend/README.md` |
| 코드 리뷰 | `common/docs/code-review/*.md` (MUST 위반 = 머지 차단) |
| CI 자동화 수정 | `common/docs/automation-spec.md` (명세·구현 위치·불변 조건) |
| 백엔드 뼈대 만들기 | `backend/README.md` |

## 커밋

`<type>:<제목>` 형식을 사용한다. type 은 소문자, `:` 뒤 공백 없음, 제목은 명령문·마침표 없음.

type: `feat` `fix` `remove` `refactor` `style` `comment` `rename` `docs` `test` `chore`. 한 커밋은 하나의 논리적 목적만 담고, 리팩터링과 동작 변경을 섞지 않는다.

## 검증

- 백엔드: `cd backend && ./gradlew ktlintCheck unitTest`. ktlint 가 실패하면 `./gradlew ktlintFormat` 후 다시 확인한다.

  `contextTest`·`restDocsTest` 는 DB·컨텍스트가 필요하므로 기본 검증에 넣지 않는다.

- 프론트엔드: `cd frontend && npm ci && npm run build` (tsc strict 포함) 통과가 최소선이다.

- 실행하지 못한 검증은 완료 보고에서 실행한 검증과 구분해 기록한다. 돌리지 않은 것을 통과했다고 적지 않는다.

## 금지

- **요청 범위 밖의 코드를 고치지 않는다.** 손대는 파일과 줄은 요청을 만족시키는 데 필요한 만큼으로 제한한다. 요청받지 않은 리팩터링·개선·이름 변경을 곁들이지 않고, 고쳐야 할 것 같으면 직접 고치는 대신 PR 본문에 적는다.

  상세는 `common/docs/code-review/rules.md` 의 "변경 범위" 절(MUST).

- 원격 상태를 바꾸는 명령(배포·삭제)을 검증 목적으로 실행하지 않는다.

- PR 머지는 사용자가 결정한다. 에이전트가 쪼갠 하위 이슈의 PR 만 리뷰어가 자동 머지한다.

- md 는 한 줄에 문장을 이어 쓰다가 150자를 넘기 전에, 문장이 끝나는 지점에서 줄을 끊는다. 줄과 줄 사이는 빈 줄로 띄운다.

  문장 중간에서 억지로 자르지 않는다 — 한 문장이 150자를 넘으면 그대로 둔다. 인용(>) 연속 줄은 `>` 한 줄로 구분한다. 표·코드 블록·frontmatter 는 예외다.
