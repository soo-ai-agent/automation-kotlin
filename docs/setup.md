# 에이전트 켜기

> **이 문서는 사람이 읽습니다.**

준비물은 토큰 두 개, 실행할 것은 스크립트 하나다. 15분이면 끝난다. 작업 장소는 두 곳뿐이며
단계마다 표시했다 — 🌐 **GitHub 웹**(브라우저) · 💻 **로컬 터미널**(저장소 clone 받은 곳).

## 순서대로 따라하기

### 1단계 — 토큰 두 개 발급 (사람이 직접, 자동화 불가)

| 토큰 | 어디서 | 발급 방법 | 왜 필요한가 |
|---|---|---|---|
| `CLAUDE_CODE_OAUTH_TOKEN` | 💻 로컬 | `npm i -g @anthropic-ai/claude-code` 후 `claude setup-token` → 브라우저 로그인 → 출력값 복사 | 일꾼·리뷰어가 Claude 를 실행하는 인증 (구독 과금) |
| `AGENT_PAT` | 🌐 웹 | Settings(계정) → Developer settings → Personal access tokens → **Fine-grained token**, 이 저장소 대상으로 **Contents · Pull requests · Issues · Actions 를 모두 Read and write** | 에이전트의 push·PR·코멘트, 그리고 하위 이슈 PR 자동 머지 |

- 두 발급 모두 브라우저 로그인이 필요한 대화형 절차라, **이 단계만은 스크립트가 대신하지 못한다.**

- **`AGENT_PAT` 은 선택이 아니다.** GitHub 는 기본 `GITHUB_TOKEN` 으로 만든 PR·커밋이
  다른 워크플로를 깨우지 못하게 막는다(무한 루프 방지). PAT 없이는 리뷰어가 붙지 않고,
  재작업 루프와 디스패처도 동작하지 않는다.

- 권한 중 하나라도 빠지면 해당 기능만 조용히 멈춘다. 아래 "안 될 때" 표를 본다.

### 2단계 — 💻 로컬에서 스크립트 한 번 실행

```bash
CLAUDE_CODE_OAUTH_TOKEN=<발급값> AGENT_PAT=<PAT> bash .github/agent/setup-agent.sh
```

몇 번을 다시 실행해도 안전하다 — 이미 있는 항목은 건너뛴다. (`gh auth login` 이 먼저 되어 있어야 한다.)

**✅ 이 한 번으로 자동으로 되는 것**

| 항목 | 내용 |
|---|---|
| 라벨 4종 | `claude`(착수 지시) · `claude-split`(분할 요청) · `claude-sent`(착수됨 마커) · `claude-made`(자동 머지 대상) |
| 시크릿 등록 | `CLAUDE_CODE_OAUTH_TOKEN` · `AGENT_PAT` |
| 워크플로 권한 | Actions 의 기본 권한을 쓰기로 열고, PR 생성·승인을 허용 |
| 기본 브랜치 보호 | 강제 푸시·삭제 차단 (private 저장소는 플랜에 따라 실패할 수 있다 — 건너뛴다) |

디스패처 폴링 스케줄(10분)은 `claude-dispatch.yml` 에 이미 들어 있어 따로 만들 것이 없다.

**❌ 스크립트가 못 하는 것 — 해당되면 사람이 챙긴다**

| 항목 | 어떻게 하나 |
|---|---|
| 토큰 발급 자체 | 1단계 — 대화형 로그인이라 자동화 불가 |
| 백엔드 뼈대 | [backend/README.md](../backend/README.md) 대로 Spring 멀티모듈을 채워 커밋 |
| 프론트 설정 | `cd frontend && cp .env.example .env` |
| 토큰 교체(로테이션) | 스크립트는 기존 값을 덮지 않는다 — 웹에서 해당 시크릿을 지운 뒤 재실행 |
| 배포 | 레지스트리·서버가 준비된 뒤 Variables 에 `DEPLOY_ENABLED=true` ([deploy.md](deploy.md)) |

### 3단계 — 🌐 웹에서 확인

이슈를 하나 만들어 본다. 예: "사용자 목록에 총 인원 수 표시" + `claude` 라벨.
10분 안에 PR 과 리뷰 코멘트가 달리면 설정이 끝난 것이다. 급하면 폴링을 바로 돌린다:

```bash
gh workflow run claude-dispatch.yml
```

이슈 잘 쓰는 법과 라벨 고르는 기준은 [issue-guide.md](issue-guide.md).

## 안 될 때

| 증상 | 확인할 곳 |
|---|---|
| 이슈 라벨을 붙여도 조용하다 | 라벨 철자, Actions 탭의 claude-dispatch 실행 여부, `AGENT_PAT` 등록 여부 |
| PR 은 생겼는데 리뷰가 안 달린다 | `AGENT_PAT` (GITHUB_TOKEN 으로 만든 PR 은 워크플로를 깨우지 못한다) |
| push·PR 생성 실패 | 워크플로 권한(2단계), PAT 의 Contents / Pull requests 권한 |
| 그래프 다음 단계가 안 돈다 | 앞 단계가 실패했는지 확인. 실패했으면 정상 동작(중단)이다 |
| 리뷰 통과인데 자동 머지가 안 된다 | 하위 이슈에 `claude-made` 라벨이 있는지. 사람이 올린 이슈는 자동 머지 대상이 아니다 |
| 재작업 루프가 안 돈다 | `AGENT_PAT` 의 **Actions: Read and write** |
| claude 단계에서 인증 오류 | `CLAUDE_CODE_OAUTH_TOKEN` 재발급. `ANTHROPIC_API_KEY` 를 같이 등록하면 API 로 과금되니 병존시키지 않는다 |
| `순차 단계는 최대 4개예요` 에러 | `CLAUDE_GRAPH` 의 `>` 가 4개를 넘었다 — `+` 로 묶거나 두 번에 나눈다 |

## 켠 다음 — 어디서 무엇을 컨트롤하나

원칙은 하나다: **스위치와 비밀값은 🌐 웹에서, 동작의 내용은 💻 로컬에서 파일을 고쳐 커밋한다.**

### 🌐 웹 (GitHub)

| 위치 | 컨트롤하는 것 |
|---|---|
| Settings → Secrets and variables → Actions | 토큰 2개(필수) · 배포 시크릿 · `DEPLOY_ENABLED` 변수 |
| Actions → claude-dispatch | 이슈 자동 착수 끄기/켜기(워크플로 비활성화), 즉시 실행 |
| Issues → Labels | `claude` = 착수 지시, `claude-split` = 하위 이슈로 분할, `claude-sent` 를 떼면 재착수 |
| PR 머지 버튼 | 사람이 올린 이슈의 PR 은 사람 몫 — 에이전트가 쪼갠 하위 이슈는 리뷰 통과 시 자동 머지 |

### 💻 저장소 파일 (로컬에서 고쳐 커밋)

| 파일 | 컨트롤하는 것 |
|---|---|
| `.github/agent/settings.env` | 그래프 모양(`CLAUDE_GRAPH`), 재수정 횟수, 러너·런타임 버전, 리뷰 통과 기준 |
| `.github/agent/nodes/<이름>.md` | 각 노드의 역할 지시문, 새 노드 추가 |
| `common/docs/code-review/rules.md` | 리뷰 규칙 — MUST(머지 차단) / SHOULD(참고 코멘트) |
| `.claude/skills/` (공통) · `backend/.claude/skills/` · `frontend/.claude/skills/` | 코딩 규칙 — 일꾼과 리뷰어가 자동으로 읽음 |

나머지 워크플로 파일은 설정이 아니라 기능 자체를 개조할 때만 연다 ([.github/README.md](../.github/README.md)).

**설정 파일은 항상 기본 브랜치의 것이 쓰인다.** 작업 브랜치에서 고쳐도 그 작업에는 반영되지
않는다 — 에이전트가 자기 규칙을 바꾸지 못하게 하려는 것이다. 설정을 바꾸려면 main 에 머지한다.

---

동작 방식과 설정은 [agent-guide.md](agent-guide.md).
