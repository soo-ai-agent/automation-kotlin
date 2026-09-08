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
| 디스패처 판단 | `.github/agent/dispatch_rules.py` | 착수·마감·삭제를 정한다 — 디스패처와 하네스가 **같은 파일**을 읽음 |
| 하네스 동작 회귀 | `common/harness-tests/cases.sh` | 같은 워크플로 (모델·GitHub 호출 없음, 갈래 하나만은 `cases.sh <갈래>`) |
| 노드의 Claude 실행 | `.github/agent/run-claude.sh` | 노드가 기본 브랜치에서 꺼내 씀 |
| 로그 정리기 | `.github/agent/stream.js` | 노드·리뷰어가 기본 브랜치에서 꺼내 씀 |
| 리뷰어 | `.github/workflows/claude-review.yml` | `pull_request` 열림/갱신 |
| 하네스 회귀 | `.github/workflows/claude-harness.yml` | `pull_request` 중 **규칙 문서를 건드린 것만** |
| 하네스 판정 케이스 | `common/harness-tests/cases/backend/`·`cases/frontend/` | 위 워크플로가 실행 (수동은 `bash common/harness-tests/run.sh [backend\|frontend\|all]`) |
| 하네스 동작 케이스 | `cases/graph/`·`cases/loop/`·`cases/state/`·`cases/next-role/`·`cases/plan/` | 같은 워크플로 (영역과 무관 — 오케스트레이션이다) |
| 하네스 형식 검사 | `common/harness-tests/static.sh` | 위 워크플로가 판정 회귀보다 **먼저** 실행 (모델 호출 없음) |
| 머지 판단 | `.github/agent/loop-decision.sh` | 리뷰어와 하네스가 **같은 파일**을 읽음 |
| 루프 상태 | `.github/agent/state.sh` | 노드·리뷰어·하네스가 **같은 도구**로 읽고 씀 |
| 전이 규칙 | `.github/agent/next-role.sh` | 다음에 어느 역할을 부를지 — 리뷰어·계획·하네스가 **같은 파일**을 읽음 |
| 계획 한 단계 | `.github/agent/plan-stage.sh` | 이번 단계의 역할과 매트릭스 — 워크플로와 하네스가 **같은 파일**을 읽음 |
| 설정 | `.github/agent/settings.env` | — |
| 노드 지시문·실행 계약 | `.github/agent/nodes/<이름>.md` | 앞머리 `---` 블록이 그 역할에 허용할 명령을 정한다 |
| 리뷰어 역할 지시문 | `.github/agent/review-role.md` | 리뷰어와 하네스가 **같은 파일**을 읽음 |
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

- `claude-agent.yml` — `plan` 잡이 `settings.env` 를 읽고 계획을 펼쳐 이번 단계의 역할을 정하면, `run` 잡이 `claude-node.yml` 을 매트릭스로 호출하고, `next` 잡이 남은 단계가 있으면 자기를 다시 부른다.

  `sN` 은 `needs: [graph, s(N-1)]` 이고 `if: needs.graph.outputs.sN != '[]'`.

- `claude-node.yml` — 잡 흐름은 파일 머리 주석의 ①준비→②Claude 실행→③후처리→④공유.

  수습은 `run_claude` 가 실패했고 `rescue` 입력이 있으면 **같은 잡 안에서** 수습 역할 지시문 + 직전 노드의 마지막 보고를 붙여 한 번 더 돌린다.

- push 경합: 같은 단계의 병렬 노드가 같은 브랜치에 push 하므로 `git pull --rebase` 후 최대 3회 재시도.

### GitLab 원본과 달라진 이유

원본은 자식 파이프라인으로 잡을 실행 중에 생성했다. GitHub Actions 에는 그 기능이 없다.

- 순차 단계 수에 제한이 없다. 잡 하나가 이번 단계를 돌린 뒤 자기를 다시 부르므로 잡을 미리 선언할 필요가 없다. 병렬(`+`)로 묶는 수에도 제한이 없다.

- 수습을 별도 잡으로 두면 단계마다 잡을 두 벌씩 선언해야 하므로 **노드 잡 안으로 넣었다.** 덕분에 노드 상태를 아티팩트로 주고받을 필요가 없어졌다.

### 수정 시 불변 조건

- 단계 잡을 다시 미리 선언하지 말 것. 그러면 상한이 되살아나고 같은 `with:` 블록을 여러 벌 관리하게 된다 — `static.sh` 가 막는다.

- `next` 잡의 `needs` 에서 `run` 을 빼지 말 것 — 실패 전파가 사라져 앞 단계가 깨진 채로 다음 단계가 돈다.

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

- **명세**: 이슈 컨텍스트이고 `split` 노드가 아닐 때, `/tmp/body.md` 에 `specs/` 가 있는지로 갈린다.

  있으면 **그 스펙이 기준**이라고 지시한다 — 명세를 새로 만들지 말고 `spec.md`·`plan.md`·`tasks.md` 를 읽어 구현하고, 어긋나면 코드를 고치고, 스펙이 틀렸다고 판단되면 보고하라는 내용이다.

  없으면 기존대로 `.claude-spec.md`(커밋 금지) 작성을 지시 → `명세를 이슈 본문에 반영` step 이 `gh issue edit` 으로 붙이고 파일을 지운다. 이때 **명세의 원본은 저장소가 아니라 이슈다.**

  **이 분기를 없애면 안 된다.** 스펙이 있는데 명세 작성을 지시하면 에이전트가 경쟁하는 두 번째 명세를 지어내 이슈 본문에 박고, 그것이 이후 노드의 기준이 되어 스펙을 밀어낸다.

- **분할**: `split` 노드가 `.claude-split/NN-*.md` 를 남기면 → `분할 파일을 하위 이슈로` step 이 파일당 `gh issue create --label claude --label claude-made`(제목=1행, 본문=나머지 +"상위 이슈: #N"), 이어서 상위 본문에 체크리스트를 붙인다.

  분할 노드는 커밋 금지 — step 끝의 `git reset --hard "$BEFORE_SHA"` 가 실수 커밋을 되돌린다.

- **PR**: `PR 생성` step — 제목은 `/tmp/body.md` 첫 줄(120자, 빈 값이면 "Claude 자동 변경"), 이슈 컨텍스트면 본문 첫 줄에 `Closes #N`.

- **착수**: 디스패처 1)단계(claude-split → `node=split`), 2)단계(claude → 개발). 두 라벨이 같이 붙으면 분할이 우선. 브랜치는 `graph` 잡이 `claude/issue-N` 으로 정한다.

- **스펙 대조**: 리뷰어(`claude-review.yml`)의 `기준 스펙 찾기` step 이 head 브랜치 `claude/issue-N` 의 이슈 본문에서 `specs/` 경로를 찾아,
  있으면 spec.md 를 리뷰 입력의 '기준 스펙' 절로 붙인다(30KB 상한). 스펙과 어긋난 구현은 차단 사유다.

### 수정 시 불변 조건

- **Claude 에게 GitHub API 권한을 주지 않는다** — Claude 는 파일만 쓰고, API 호출은 셸이 한다. `GH_TOKEN` 을 잡 레벨 `env` 로 올리지 말 것.

  **리뷰어도 같다.** 잡 레벨에 올리면 `claude` 를 돌리는 '리뷰' step 도 토큰을 갖고, 모델이 `Bash` 로 `gh` 를 불러
  `AGENT_PAT` 권한을 쓸 수 있다. 실제로 그 상태였다 — 노드는 규칙을 지키는데 리뷰어만 어기고 있었다.

- **리뷰어는 읽기 도구만 받는다** (`--allowedTools "Read,Grep,Glob"`). 코드를 고치지 않는다는 것을 지시문으로만
  말하지 않고 도구로 막는다. 하네스(`run.sh`)도 같은 제한으로 부른다 — 안 맞추면 실제 리뷰어를 재지 못한다.

  `--allowedTools` 는 git 과 gradle/npm 검증 명령만 허용한다.

- **허용 명령은 역할마다 다르고, 그 역할의 노드 파일이 정한다.** `run-claude.sh` 의 `BASE_TOOLS` 는 모든 노드가 갖는 읽기 전용 git 뿐이고,
  커밋·빌드 명령은 `nodes/<이름>.md` 앞머리 `allowed-tools:` 가 얹는다. 여기에 공통으로 더하면 역할 분리가 도로 무너진다.

  계약이 없는 역할은 읽기 전용 git 만 받는다 — 모르는 역할에 권한을 주는 쪽이 아니라 **막는 쪽**으로 떨어져야 한다.

  커밋 지시문도 계약에서 파생된다: `git commit` 권한이 없는 역할에게는 `build_prompt` 가 "커밋하지 마라"를 대신 붙인다.
  시켜 놓고 못 하게 하면 그 자리에서 막히므로, 두 곳에 따로 적지 않고 한쪽에서 끌어낸다.

- `.claude-split/`·`.claude-spec.md` 는 커밋되면 안 된다 — 처리 step 이 파일을 지우는 순서를 `남은 변경 커밋` step **앞**으로 유지할 것.

- 하위 이슈 라벨은 `claude,claude-made` 둘 다여야 한다 — `claude` 가 빠지면 착수가 안 되고, `claude-made` 가 빠지면 자동 머지가 안 된다.

- `gh issue view`/`gh issue comment` 는 PR 번호를 받지 못한다. `context_type=pr`(리뷰 fix 루프)에서는 `gh pr` 계열을 써야 한다.

- 스펙 경로를 못 찾거나 파일이 없으면 **스펙 대조 없이** 기존 기준으로만 판정한다 — 이슈 조회 실패가 리뷰를 죽이면 안 된다.

## 3. 완료 후 무인 정리

### 먼저 — GitHub 이 이미 하는 일은 GitHub 에게 맡긴다

- **머지된 PR 의 이슈 마감** — PR 본문에 `Closes #N` 이 들어가므로 GitHub 이 머지 순간 닫는다.
  디스패처가 같은 일을 또 하고 있었다. 열린 이슈만 조회하므로 정상 경로에서는 아무 일도 안 하는 코드였다.

- **머지된 브랜치 삭제** — 저장소 설정 `delete_branch_on_merge` 를 `setup-agent.sh` 4절이 켠다.
  디스패처의 브랜치 청소는 이제 **PR 을 열지 못한 채 끝난 브랜치**만 담당한다 —
  실행 상한에 걸려 `make_pr` 노드까지 못 간 경우가 그렇다.

  **정리를 새로 만들기 전에 GitHub 에 같은 기능이 있는지 먼저 본다.** 스크립트로 하면 읽고 믿어야 할 코드가 늘고,
  10분 주기로 도는 만큼 API 도 더 쓴다.

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

- **치우는 판단은 `dispatch_rules.py` 에만 둔다.** `dispatch.py` 는 묻고 그대로 실행한다.
  판단이 `dispatch.py` 안으로 되돌아가면 하네스가 못 재고, 그 상태로 10분마다 돈다 — `static.sh` 가 막는다.

  그 규칙은 GitHub 을 부르지 않는다. `urllib`·`subprocess` 를 가져오는 순간 하네스가 돌릴 수 없게 된다.

- 게이트 순서를 유지할 것: 판별 불가(브랜치명 불일치, 이슈 조회 실패)면 **머지하지 않는 쪽**으로 떨어져야 한다.

  같은 원칙이 정리에도 적용된다 — 이슈 조회 실패는 `unknown` 이고, `compare` 실패는 `ahead_by=None` 이다.
  둘 다 건드리지 않는 쪽으로 떨어진다. **못 물어봤다는 것이 없다는 뜻은 아니다.**

- 에이전트 토큰으로 기본 브랜치에 직접 push 하는 코드를 만들지 말 것 — 보호가 막는 것이 정상이다.

## 5. 구조·문서

### 요구사항

- 코딩 규칙 스킬은 3모듈: 공통 `.claude/skills/`(ponytail 계열·oop-responsibility-design·algorithm-implementation·md-doc·api-contract), 백엔드 `backend/.claude/skills/`(kotlin-* 17종), 프론트 `frontend/.claude/skills/`(frontend-* 8종).

  공통 스킬은 고치는 파일의 위치와 무관하게 항상 적용되고, 영역 스킬은 위치가 정한다 (디렉터리 스코프 스킬).

- 문서는 독자 기준 분리: `docs/` = **사용자 전용**. 에이전트 규칙은 루트 `CLAUDE.md`·`AGENTS.md`(도구 규약상 루트 고정) + 모듈별 스킬 + `common/docs/`(리뷰 규칙·이 문서).

  `.github/README.md` 는 CI 파일 지도로 사람이 읽는다.

- 경계 문서 2개는 이동 금지: `TASK.md`(사용자→에이전트 주문), `CONTRACT.md`(api 노드→web 노드 계약, 노드 지시문이 루트 경로를 참조).

### 수정 시 불변 조건

- 리뷰어 프롬프트(`claude-review.yml`)와 `settings.env` 의 `CLAUDE_REVIEW_BAR` 에 있는 스킬 경로는 **문자열 하드코딩**이다 — 스킬을 옮기면 두 곳을 같이 고칠 것 (`.claude/skills/oop-responsibility-design`, `backend/.claude/skills/kotlin-*`, `frontend/.claude/skills/frontend-*`).

- `CLAUDE.md`·`AGENTS.md` 는 루트에서 옮길 수 없다 (Claude Code·Codex 가 루트에서 읽는다).

- `CLAUDE.md` 의 `@common/docs/code-review/rules.md` import 경로와 `settings.env` 의 `CLAUDE_REVIEW_RULES_DIR` 은 같은 곳을 가리켜야 한다.

- **계획은 잡을 미리 선언하지 않는다.** `claude-agent.yml` 의 잡은 셋이고 단계 수와 무관하다 —
  `plan`(이번 단계를 고른다) · `run`(그 역할들을 나란히 돌린다) · `next`(남았으면 `stage+1` 로 자기를 다시 부른다).

  예전에는 단계마다 잡(`s1`~`s4`)을 선언해 두고 `graph.js` 의 `MAX_STAGES` 로 맞췄다.
  Actions 가 잡을 실행 중에 만들 수 없어서였고, 그래서 순차 4단계가 상한이었고 같은 `with:` 블록이 네 벌 복사돼 있었다.

  **이제 상한이 없으므로 루프가 스스로 멈춰야 한다.** `CLAUDE_MAX_STEPS` 가 그 상한이고 `next-role.sh` 가 잰다.
  `GITHUB_TOKEN` 재귀는 Actions 가 막아 주지만 **PAT 재귀는 막아 주지 않는다** — 이 상한이 유일한 정지선이다.

  병렬(`+`)은 `run` 잡의 matrix 로 살아 있다. `next-role.sh` 가 이번 단계의 역할을 공백으로 이어 내고,
  `run` 이 그만큼 나란히 돈다. 실행 횟수는 그 수만큼 오른다.

- **하네스 회귀(`claude-harness.yml`)는 PR 브랜치를 checkout 한다** — 리뷰어와 반대다.
  리뷰어는 PR 이 자기 심사 기준을 바꾸지 못하게 기준 브랜치 설정을 쓰지만, 하네스는 그 PR 이 바꾼 규칙이 검사 대상이라 PR 것을 읽어야 한다.

- 하네스의 `paths` 필터는 **규칙을 담은 파일 목록**이다 — 규칙 문서를 새 경로에 만들면 이 목록에 더할 것.
  빠뜨리면 규칙이 바뀌어도 회귀가 돌지 않아 조용히 통과한다.

  노드의 실행 계약(`nodes/**`)과 그것을 적용하는 `run-claude.sh` 도 이 목록에 있다. 형식 검사가 계약의 어긋남을 잡기 때문이다.
  대신 이 목록에 걸린 PR 은 모두 판정 회귀 7건을 함께 치른다 — 잡 하나가 검사 일곱을 순서대로 돌리기 때문이고, 지금은 그 비용을 받아들인다.

- **하네스는 영역별로 갈린다** — 케이스는 `cases/backend/`·`cases/frontend/` 에 나눠 둔다.
  영역은 **어느 케이스를 돌릴지만** 고르고, CI 는 영역 구분 없이 `all` 로 전부 돌린다.

  영역마다 **PASS 기대 케이스를 최소 하나** 남긴다. 차단 기대 케이스만 있으면 "전부 막는 리뷰어"도 만점을 받는다.

- **리뷰어 역할은 `.github/agent/review-role.md` 한 곳에만 적는다.** 실제 리뷰어(`claude-review.yml`)와
  하네스(`run.sh`)가 같은 파일을 읽고, 규칙 전문·통과 기준(`CLAUDE_REVIEW_BAR`)·`--add-dir` 까지 같은 것을 쓴다.

  하네스가 자기 프롬프트를 따로 쓰면 **하네스가 통과해도 실제 리뷰어의 회귀를 못 잡는다.** 실제로 그 상태였다 —
  `CLAUDE_REVIEW_BAR` 를 망가뜨려도 하네스는 그 문자열을 아예 안 읽어 초록불이었다. `static.sh` 가 이 공유를 검사한다.

- **검사는 여덟으로 나눈다** — `static.sh`(형식) · `graph.sh`(그래프 펼치기) · `loop.sh`(머지 판단) · `state.sh`(루프 상태) ·
  `next-role.sh`(전이 규칙) · `plan.sh`(계획 루프) · `dispatch.sh`(착수·정리 판단)는 모델을 안 불러 공짜고,
  `run.sh` 만 케이스당 claude 호출 1건이다.

- **`plan.sh` 만 여러 바퀴를 이어 돌린다.** 나머지는 규칙 하나에 값을 넣어 답 하나를 본다.
  한 바퀴씩은 맞는데 이어 돌리면 안 되는 결함이 있고, 그것은 이어 돌려야만 보인다.

- **리뷰 뒤에 어느 역할을 부를지는 `next-role.sh` 가 정한다.** 규칙은 위에서 아래로 읽고 먼저 걸리는 것이 이긴다.

  | 순서 | 상황 | 결과 |
  |---|---|---|
  | ① | 상태를 못 읽음(`broken=1`) | `human` |
  | ② | 횟수가 숫자가 아님 | `human` |
  | ③ | 통과(`PASS`) | `done` |
  | ④ | 실행 횟수가 `CLAUDE_MAX_STEPS` 이상 | `human` |
  | ⑤ | `AGENT_PAT` 없음 | `loop-off` |
  | ⑥ | 판정 없음 + 계획에 남은 역할 있음 | 그 역할들 |
  | ⑥ | 판정 없음 + 계획 끝 | `done` |
  | ⑦ | 라운드가 `CLAUDE_MAX_ROUNDS` 이상 | `human` |
  | ⑧ | 지적 남음(`CHANGES_REQUESTED`) | `fix` |
  | ⑨ | 모르는 판정 | `human` |

  **판정이 없다는 것은 계획을 밟는 중이라는 뜻이다.** 리뷰어는 언제나 판정을 채워 부르므로
  (`claude-review.yml` 이 `PASS` 아니면 `CHANGES_REQUESTED` 로 정한다) 빈 판정은 `claude-agent.yml` 에서만 온다.

  **③ 을 ④⑤ 보다 앞에 두는 것이 중요하다.** 상한과 PAT 은 일을 더 시킬 수 있는지를 재는 것이고
  통과는 시킬 일이 없다는 뜻이라, 순서를 뒤집으면 통과한 PR 까지 사람을 부르며 막힌다.

  **⑥(계획)을 ⑦(라운드 상한)보다 앞에 두는 것도 그만큼 중요하다.** 계획 중에는 리뷰가 돈 적이 없어
  라운드가 0 이고 상한도 넘어오지 않아 0 이다. 순서를 뒤집으면 `0 >= 0` 이 걸려 **루프가 첫 걸음에서 막힌다.**
  실제로 그렇게 막혔고, 규칙 하나씩 보는 케이스로는 안 보여 계획 루프 회귀(`plan.sh`)가 잡았다.

  `CLAUDE_MAX_ROUNDS` 와 `CLAUDE_MAX_STEPS` 는 다른 상한이다 — 저쪽은 같은 PR 을 몇 번 다시 보는지,
  이쪽은 작업 하나에서 노드가 통틀어 몇 번 도는지다.

  **왜 그렇게 정했는지는 stdout 이 아니라 stderr 로 낸다.** stdout 은 대조할 수 있게 한 단어로 두고,
  사람에게 남길 말은 따로 보낸다 — 리뷰어가 이유를 짐작해 지어내지 않게.

  **두 판단의 경계를 지킬 것.** `loop-decision.sh` 는 머지만, `next-role.sh` 는 다음에 무엇을 돌릴지만 정한다.
  "계속할까"를 양쪽에서 재면 상한 하나를 바꿀 때 두 군데를 고쳐야 한다.

- **루프 상태는 이슈·PR 코멘트 안의 숨은 블록에 있다.** 노드가 실행 횟수와 마지막 역할·결과를,
  리뷰어가 라운드와 판정을 얹는다. 코멘트가 쌓이면 블록도 쌓이고, **가장 나중 블록이 지금 상태**다.

  블록은 이렇게 생겼다. HTML 주석이라 화면에는 안 보이고, 코멘트 본문 끝에 붙는다.

  ```
  <!-- claude-state
  round=2
  step=5
  last_role=code
  last_status=0
  verdict=CHANGES_REQUESTED
  broken=0
  -->
  ```

  다른 자리를 고르지 않은 이유: 저장소 커밋은 `.claude-split/`·`.claude-spec.md` 를 커밋하지 않는 규약과 어긋나고 PR diff 를 더럽힌다.
  Actions 아티팩트는 실행 하나에 묶여 루프가 자기를 재호출하면 이어지지 않는다. 라벨은 값이 아니라 표시다.

  **블록이 아예 없는 것(아직 한 번도 안 돎)과 있는데 못 읽는 것(`broken=1`)은 다르다.** 섞으면 처음과 고장을 구분할 수 없다.
  `broken=1` 일 때 무엇을 할지는 상태가 정하지 않는다 — 다음 역할을 고르는 쪽이 정한다.

  **아직 이 값을 읽어 판단하는 곳은 없다.** 라운드는 여전히 리뷰 코멘트 개수로 센다. 읽는 쪽을 옮기는 것은 다음 단계다.

- **그래프와 루프는 모델 없이 잰다.** 잴 수 있는 이유는 그 판단이 워크플로 셸이 아니라 값만 받는 도구로 나와 있기 때문이다 —
  그래프는 `graph.js`(환경변수 in → 단계 매트릭스 out), 루프는 `loop-decision.sh`(값 in → 결정 한 단어 out).

  **판단을 워크플로 YAML 안으로 되돌리면 그 축의 회귀 검사가 통째로 죽는다.** `static.sh` 가 둘 다 검사한다 —
  리뷰어가 `loop-decision.sh` 를 기준 브랜치에서 꺼내 쓰는지, 그리고 그 결정대로 실행하는지까지 본다.

  셋 다 고치기 전에 결과를 미리 보는 데도 쓴다: `graph.sh '<표현식>'` 은 워크플로를 돌리지 않고 그래프를 펼쳐 보고,
  `loop.sh table` 은 상황별 결정을 표로 뽑고, `state.sh show` 는 상태를 읽고 갱신해 다시 쓰는 과정을 보여 준다.

  "규칙이 옳은가"는 `run.sh` 가, **"규칙이 읽히기는 하는가"** 는 `static.sh` 가 본다. 링크가 죽거나 경로가
  어긋나면 규칙은 파일에 남아 있어도 아무도 안 읽는데, 이건 모델을 안 불러도 잡힌다.

- 문서를 추가할 때 독자를 정하고 위치를 고른다: 사용자 → `docs/`, 에이전트 → `common/docs/` 또는 스킬. `docs/README.md` 머리의 경계 선언을 유지할 것.
