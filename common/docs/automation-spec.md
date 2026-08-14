# CI 자동화 명세

> **이 문서는 에이전트가 읽습니다.** 이 저장소의 CI 자동화(오케스트레이션·이슈 자동화· 무인 정리·권한 경계·문서 구조)를 **수정하려는 에이전트를 위한** 기술 명세다.

> 각 절은 요구사항 → 구현 위치(파일·함수) → **수정 시 지켜야 할 불변 조건** 순이다.

> 사용자용 사용법은 [docs/](../../docs/README.md), 동작 개요는 [docs/agent-guide.md](../../docs/agent-guide.md), 파일 지도는 [.github/README.md](../../.github/README.md).

## 0. 전체 지형

| 부품 | 파일 | 트리거 |
|---|---|---|
| 디스패처 | `.github/workflows/claude-dispatch.yml` | 스케줄 (10분) + 수동 |
| 진입점(그래프) | `.github/workflows/claude-agent.yml` | `workflow_dispatch` |
| 노드 본체 | `.github/workflows/claude-node.yml` | `workflow_call` (진입점이 호출) |
| 그래프 펼치기 | `.github/agent/graph.js` | 진입점의 `graph` 잡이 실행 |
| 디스패처 로직 | `.github/agent/dispatch.py` | `claude-dispatch.yml` 이 `start`·`cleanup` 두 번 실행 |
| 노드의 Claude 실행 | `.github/agent/run-claude.sh` | 노드가 기본 브랜치에서 꺼내 씀 |
| 로그 정리기 | `.github/agent/stream.js` | 노드·리뷰어가 기본 브랜치에서 꺼내 씀 |
| 리뷰어 | `.github/workflows/claude-review.yml` | `pull_request` 열림/갱신 |
| 설정 | `.github/agent/settings.env` | — |
| 노드 지시문 | `.github/agent/nodes/<이름>.md` | — |
| 서버 세팅 | `.github/agent/setup-agent.sh` | 사용자가 1회 실행 |

라벨 규약: `claude`(착수 동의) · `claude-split`(분할 요청) · `claude-sent`(착수됨 마커) · `claude-made`(에이전트가 만든 하위 이슈 — **자동 머지 대상 판별 키**).

**설정과 도구는 항상 기본 브랜치에서 읽는다.** `settings.env`·`nodes/*.md`·`stream.js`·`run-claude.sh` 모두 `git show origin/$DEF:...` 로 꺼낸다 (`graph.js`·`dispatch.py` 는 기본 브랜치를 checkout 해서 쓴다).

작업 브랜치에 파일이 없거나 에이전트가 그 파일을 고쳐도 잡이 깨지지 않아야 하고, PR 브랜치가 자기 리뷰 기준을 바꾸지 못해야 하기 때문이다.

## 1. 오케스트레이션 (그래프)

### 요구사항

- `CLAUDE_GRAPH` 문법: `a>b` 순차, `a+b` 병렬, `a?b` 는 a 실패 시 b 노드가 수습.

- 노드들은 **같은 브랜치**를 이어받는다. 앞 노드의 파일과 커밋을 그대로 보고 작업한다.

- 수습(`?`) 노드는 대상 노드가 실패했을 때만 일하고, 성공이면 아무것도 하지 않는다.

- PR 은 마지막 단계의 마지막 노드 하나만 만든다.

- 수습이 없는 노드가 실패하면 뒤 단계는 돌지 않는다.

### 구현

- `graph.js` — `CLAUDE_GRAPH` 파싱·검증(이름 규칙 `[a-z][a-z0-9_]*`, 역할 파일 부재 경고) → 단계별 매트릭스 JSON 을 `GITHUB_OUTPUT` 의 `s1`..`s4` 로.

  항목은 `{ node, label, rescue, make_pr }`. `CLAUDE_NODE` 가 있으면 그 노드 하나만 `s1` 에 담는다.

- `claude-agent.yml` — `graph` 잡이 `settings.env` 를 읽고 브랜치명과 런타임 버전을 outputs 로 낸 뒤, 단계 잡 `s1`..`s4` 가 `claude-node.yml` 을 매트릭스로 호출한다.

  `sN` 은 `needs: [graph, s(N-1)]` 이고 `if: needs.graph.outputs.sN != '[]'`.

- `claude-node.yml` — 잡 흐름은 파일 머리 주석의 ①준비→②Claude 실행→③후처리→④공유.

  수습은 `run_claude` 가 실패했고 `rescue` 입력이 있으면 **같은 잡 안에서** 수습 역할 지시문 + 직전 노드의 마지막 보고를 붙여 한 번 더 돌린다.

- push 경합: 같은 단계의 병렬 노드가 같은 브랜치에 push 하므로 `git pull --rebase` 후 최대 3회 재시도.

### GitLab 원본과 달라진 이유

원본은 자식 파이프라인으로 잡을 실행 중에 생성했다. GitHub Actions 에는 그 기능이 없다.

- 단계 잡을 **미리 선언**해야 해서 순차 단계가 **최대 4개**로 제한된다 (`graph.js` 의 `MAX_STAGES`). 병렬(`+`)로 묶는 수에는 제한이 없다.

- 수습을 별도 잡으로 두면 단계마다 잡을 두 벌씩 선언해야 하므로 **노드 잡 안으로 넣었다.** 덕분에 노드 상태를 아티팩트로 주고받을 필요가 없어졌다.

### 수정 시 불변 조건

- `MAX_STAGES` 를 늘리려면 `claude-agent.yml` 에 같은 모양의 단계 잡을 **먼저 추가**해야 한다. 숫자만 바꾸면 5번째 단계가 조용히 사라진다.

- 단계 잡의 `needs` 에서 앞 단계를 빼지 말 것 — 실패 전파가 사라져 앞 노드가 깨진 채로 뒤 노드가 돈다.

- `strategy.fail-fast: false` 를 지우지 말 것 — 병렬 노드 하나가 실패하면 나머지가 중도 취소된다.

- 매트릭스가 빈 배열이면 GitHub 이 에러를 낸다. `if: ... != '[]'` 가드를 지우지 말 것.

- `make_pr` 는 `graph.js` 가 마지막 단계의 마지막 노드에만 준다. 여러 노드가 참이 되면 병렬 막차끼리 PR 생성이 경합한다.

## 2. 이슈 중심 자동화

### 요구사항

- `claude-split` 이슈는 분할 노드가 **독립적으로 머지 가능한** 하위 이슈 2~6개로 쪼갠다. 하위 이슈는 `claude,claude-made` 라벨로 생성되어 자동 착수·자동 머지 대상이 된다.

- 상위 이슈 본문에 `## 하위 이슈` 체크리스트(`- [ ] #N 제목`)가 생긴다.

- 본문이 빈약한 이슈는 에이전트가 배경·할 일·완료 기준을 정의해 **이슈 본문에 반영**하고 그 기준대로 구현한다.

- PR 제목 = 작업 지시 첫 줄(이슈 제목). 이슈 착수 PR 본문에 `Closes #N`.

### 구현 (전부 `claude-node.yml`)

- **지시 확정**: `prompt` 입력이 있으면 그것을(`@경로` 면 그 파일을), 없고 `issue` 가 있으면 `gh issue view` 로 제목+본문을 읽어 `/tmp/body.md` 에 담는다.

  **디스패처는 이슈 본문을 워크플로 입력으로 넘기지 않는다** — `workflow_dispatch` 입력 길이 제한에 걸릴 수 있어서다.

- **명세**: 이슈 컨텍스트이고 `split` 노드가 아니면 프롬프트에 `.claude-spec.md`(커밋 금지) 작성을 지시 → `명세를 이슈 본문에 반영` step 이 `gh issue edit` 으로 붙이고 파일을 지운다.

  **명세의 원본은 저장소가 아니라 이슈다.**

- **분할**: `split` 노드가 `.claude-split/NN-*.md` 를 남기면 → `분할 파일을 하위 이슈로` step 이 파일당 `gh issue create --label claude --label claude-made`(제목=1행, 본문=나머지 +"상위 이슈: #N"), 이어서 상위 본문에 체크리스트를 붙인다.

  분할 노드는 커밋 금지 — step 끝의 `git reset --hard "$BEFORE_SHA"` 가 실수 커밋을 되돌린다.

- **PR**: `PR 생성` step — 제목은 `/tmp/body.md` 첫 줄(120자, 빈 값이면 "Claude 자동 변경"), 이슈 컨텍스트면 본문 첫 줄에 `Closes #N`.

- **착수**: 디스패처 1)단계(claude-split → `node=split`), 2)단계(claude → 개발). 두 라벨이 같이 붙으면 분할이 우선. 브랜치는 `graph` 잡이 `claude/issue-N` 으로 정한다.

### 수정 시 불변 조건

- **Claude 에게 GitHub API 권한을 주지 않는다** — Claude 는 파일만 쓰고, API 호출은 셸이 한다. `GH_TOKEN` 을 잡 레벨 `env` 로 올리지 말 것.

  `--allowedTools` 는 git 과 gradle/npm 검증 명령만 허용한다.

- `.claude-split/`·`.claude-spec.md` 는 커밋되면 안 된다 — 처리 step 이 파일을 지우는 순서를 `남은 변경 커밋` step **앞**으로 유지할 것.

- 하위 이슈 라벨은 `claude,claude-made` 둘 다여야 한다 — `claude` 가 빠지면 착수가 안 되고, `claude-made` 가 빠지면 자동 머지가 안 된다.

- `gh issue view`/`gh issue comment` 는 PR 번호를 받지 못한다. `context_type=pr`(리뷰 fix 루프)에서는 `gh pr` 계열을 써야 한다.

## 3. 완료 후 무인 정리

### 요구사항 — "만든 주체가 끝낸다"

- **에이전트가 만든 것은 에이전트가 끝낸다**: `claude-made` 하위 이슈의 PR 은 리뷰 PASS 시 자동 머지, 이슈는 자동 닫힘(Closes), 브랜치는 자동 삭제.

- **사용자가 만든 것은 사용자가 끝낸다**: 사용자가 올린 이슈의 PR 은 사용자가 머지하고, 분할 상위 이슈는 **자동으로 닫지 않고** 완료 보고를 달아 사용자가 닫는다.

- 어떤 경로로 끝났든 잔여물(열린 이슈·PR·브랜치)이 남지 않는다.

### 구현 (디스패처의 3~6단계 + 리뷰어)

- **자동 머지**: 리뷰어 `통과 — 자동 머지 판단` step. PASS 이고 head 브랜치가 `claude/issue-N` 이고 이슈 N 에 `claude-made` 라벨이 있을 때만 `gh pr merge --squash --delete-branch`.

  아니면 "머지는 사람 몫" 로그만. 실패(충돌·권한) 시 ⚠️ 코멘트로 사용자를 부른다.

- **3) 분할 상위**: 본문 체크리스트에서 닫힌 하위를 `[x]` 로 갱신. 전부 닫히면 `REPORT_MARK`("📦 하위 작업 완료 보고") 코멘트를 **한 번만** 게시 — 하위 이슈별 제목· 머지된 PR 링크·커밋 제목(≤10)·변경 파일(≤12).

  **상위는 닫지 않는다.** 멱등성: 기존 코멘트에 REPORT_MARK 가 있으면 재게시하지 않는다.

- **4) 이슈 청소**: `claude,claude-sent` 열린 이슈 중 `claude/issue-N` 브랜치에 **머지된 PR 이 있고 열린 PR 이 없는** 것만 코멘트 후 닫음 (`claude-split` 상위는 3)이 담당).

- **5) PR 청소**: `claude/issue-N` head 의 열린 PR 중 이슈가 닫힌 것 → 코멘트 후 닫고 브랜치 삭제 (diff 는 닫힌 PR 에 보존됨). 사람 브랜치의 PR 은 이름 규칙으로 제외.

- **6) 브랜치 청소**: `claude/*` 중 열린 PR 이 없고, 기본 브랜치와 비교해 `ahead_by == 0` 인 것 삭제. GitHub 브랜치 API 에는 `merged` 플래그가 없어 `compare` 로 판정한다.

- `CAN_START = HAS_PAT` — PAT 이 없어도 청소(3~6)는 돈다(착수 1·2만 생략).

### 수정 시 불변 조건

- 청소는 **보수적으로**: "머지된 적 없음 = 사용자가 판단할 몫"이라 닫지 않는다. 이 기준을 완화하면 진행 중 작업을 파괴할 수 있다.

- 상위 이슈를 자동 마감으로 되돌리지 말 것 — "사용자가 만든 것은 사용자가 끝낸다"가 사용자가 확정한 정책이다.

- 완료 보고의 멱등 마커(`REPORT_MARK` 문자열)를 바꾸면 기존 상위 이슈에 보고가 중복 게시된다.

- `/issues` 응답에는 PR 이 섞여 온다. `"pull_request" not in it` 필터를 지우지 말 것.

- 6)의 `ahead_by` 판정에서 예외가 나면 **삭제하지 않는 쪽**으로 떨어져야 한다.

## 4. 권한 경계

### 요구사항

- 기본 브랜치는 보호 브랜치 — 직접 푸시 금지.

- 자동 머지는 `claude-made` 이슈의 PR 로 한정. 사용자가 올린 이슈·직접 호출 작업의 PR 은 사용자만 머지한다.

- `AGENT_PAT` 은 **선택이 아니다.** 기본 `GITHUB_TOKEN` 으로 만든 PR·커밋은 다른 워크플로를 깨우지 못한다(무한 루프 방지 정책). PAT 이 없으면 리뷰어가 붙지 않고, 재작업 루프와 디스패처 착수도 동작하지 않는다.

### 구현

- `setup-agent.sh` 3·4절: 워크플로 권한 쓰기 허용, 기본 브랜치 보호 — 둘 다 멱등이고 권한이 없으면 안내만 남기고 넘어간다.

- 리뷰어 `통과 — 자동 머지 판단` step 의 2중 게이트: ① head 브랜치명이 `claude/issue-N` 인가 ② 그 이슈에 `claude-made` 라벨이 있는가.

### 수정 시 불변 조건

- 게이트 순서를 유지할 것: 판별 불가(브랜치명 불일치, 이슈 조회 실패)면 **머지하지 않는 쪽**으로 떨어져야 한다.

- 에이전트 토큰으로 기본 브랜치에 직접 push 하는 코드를 만들지 말 것 — 보호가 막는 것이 정상이다.

## 5. 구조·문서

### 요구사항

- 코딩 규칙 스킬은 3모듈: 공통 `.claude/skills/`(ponytail 계열·oop-responsibility-design), 백엔드 `backend/.claude/skills/`(kotlin-* 9종), 프론트 `frontend/.claude/skills/`(frontend-react).

  적용 규칙은 고치는 파일의 위치가 정한다 (디렉터리 스코프 스킬).

- 문서는 독자 기준 분리: `docs/` = **사용자 전용**. 에이전트 규칙은 루트 `CLAUDE.md`·`AGENTS.md`(도구 규약상 루트 고정) + 모듈별 스킬 + `common/docs/`(리뷰 규칙·이 문서).

  `.github/README.md` 는 CI 파일 지도로 사람이 읽는다.

- 경계 문서 2개는 이동 금지: `TASK.md`(사용자→에이전트 주문), `CONTRACT.md`(api 노드→web 노드 계약, 노드 지시문이 루트 경로를 참조).

### 수정 시 불변 조건

- 리뷰어 프롬프트(`claude-review.yml`)와 `settings.env` 의 `CLAUDE_REVIEW_BAR` 에 있는 스킬 경로는 **문자열 하드코딩**이다 — 스킬을 옮기면 두 곳을 같이 고칠 것 (`.claude/skills/oop-responsibility-design`, `backend/.claude/skills/kotlin-*`, `frontend/.claude/skills/frontend-react`).

- `CLAUDE.md`·`AGENTS.md` 는 루트에서 옮길 수 없다 (Claude Code·Codex 가 루트에서 읽는다).

- `CLAUDE.md` 의 `@common/docs/code-review/rules.md` import 경로와 `settings.env` 의 `CLAUDE_REVIEW_RULES_DIR` 은 같은 곳을 가리켜야 한다.

- 문서를 추가할 때 독자를 정하고 위치를 고른다: 사용자 → `docs/`, 에이전트 → `common/docs/` 또는 스킬. `docs/README.md` 머리의 경계 선언을 유지할 것.
