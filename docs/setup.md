# 에이전트 켜기

> **이 문서는 사람이 읽습니다.**

준비물은 토큰 두 개, 실행할 것은 스크립트 하나다.

작업 장소는 두 곳뿐이며 단계마다 표시했다 — 🌐 **GitHub 웹**(브라우저) · 💻 **로컬 터미널**(저장소를 clone 받은 곳).

용어(일꾼·리뷰어·디스패처·노드·그래프)가 낯설면 [README 의 "먼저 알아둘 말 여섯 개"](../README.md#먼저-알아둘-말-여섯-개) 를 먼저 본다.

## 시작 전 확인

아래가 안 되어 있으면 2단계에서 막힌다.

- [ ] [gh CLI](https://cli.github.com) 설치 후 `gh auth login` 까지 완료 — `gh repo view` 가 이 저장소를 보여주면 된다

- [ ] Node.js 18 이상 — `node -v` 로 확인. 토큰 발급 도구를 npm 으로 설치한다

- [ ] 저장소가 GitHub 에 올라가 있다 — 에이전트는 push 된 코드만 본다

- [ ] Claude 구독(Pro 또는 Max) — 에이전트가 Claude 를 실행하는 데 쓴다

## 1단계 — 토큰 두 개 발급

이 단계만은 스크립트가 대신하지 못한다. 둘 다 브라우저 로그인이 필요한 대화형 절차이기 때문이다.

### `CLAUDE_CODE_OAUTH_TOKEN` — 💻 로컬에서

에이전트가 Claude 를 실행할 때 쓰는 인증이다. 구독으로 과금된다.

```bash
npm install -g @anthropic-ai/claude-code
claude setup-token
```

브라우저가 열리고 로그인하면 터미널에 값이 출력된다. 그 값을 복사해 둔다.

### `AGENT_PAT` — 🌐 GitHub 웹에서

에이전트가 코드를 push 하고, PR·코멘트를 만들고, 하위 이슈의 PR 을 자동 머지할 때 쓰는 토큰이다.

계정 Settings → Developer settings → Personal access tokens → **Fine-grained token** 으로 발급한다.

이 저장소를 대상으로 지정하고, **Contents · Pull requests · Issues · Actions 네 가지를 모두 Read and write** 로 준다.

> **`AGENT_PAT` 은 선택이 아니다.** GitHub 은 기본 제공 토큰(`GITHUB_TOKEN`)으로 만든 PR·커밋이 다른 워크플로를 깨우지 못하게 막아 둔다. 워크플로가 서로를 끝없이 부르는 것을 방지하려는 GitHub 의 정책이다.
>
> 그래서 PAT 이 없으면 일꾼이 PR 을 열어도 리뷰어가 붙지 않고, 재작업 루프와 디스패처도 돌지 않는다.

권한 중 하나라도 빠지면 그 기능만 조용히 멈춘다. 무엇이 안 되는지는 아래 "안 될 때" 표를 본다.

## 2단계 — 💻 로컬에서 스크립트 한 번 실행

```bash
CLAUDE_CODE_OAUTH_TOKEN=<발급값> AGENT_PAT=<PAT> bash .github/agent/setup-agent.sh
```

몇 번을 다시 실행해도 안전하다 — 이미 있는 항목은 건너뛴다.

**✅ 이 한 번으로 자동으로 되는 것**

| 항목 | 내용 |
|---|---|
| 라벨 4종 | `claude`(에이전트에게 맡김) · `claude-split`(쪼개서 맡김) · `claude-sent`(일을 시작했다는 표시) · `claude-made`(에이전트가 만든 하위 이슈) |
| 시크릿 등록 | `CLAUDE_CODE_OAUTH_TOKEN` · `AGENT_PAT` |
| 워크플로 권한 | Actions 의 기본 권한을 쓰기로 열고, PR 생성·승인을 허용 |
| 기본 브랜치 보호 | 강제 푸시·삭제 차단 (private 저장소는 플랜에 따라 실패할 수 있는데, 그러면 건너뛴다) |

이슈를 훑는 주기(10분)는 워크플로 파일에 이미 들어 있어 따로 만들 것이 없다.

**❌ 스크립트가 못 하는 것 — 해당되면 사람이 챙긴다**

| 항목 | 어떻게 하나 |
|---|---|
| 토큰 발급 자체 | 1단계 — 대화형 로그인이라 자동화할 수 없다 |
| 백엔드 뼈대 | [backend/README.md](../backend/README.md) 대로 Spring 멀티모듈을 채워 커밋 |
| 프론트 설정 | 없음 — 주소·키는 `frontend/app.json` 의 `extra` 에 있고 기본값으로 바로 뜬다 |
| 토큰 교체(로테이션) | 스크립트는 기존 값을 덮지 않는다 — 웹에서 해당 시크릿을 지운 뒤 다시 실행 |
| 배포 | 레지스트리·서버가 준비된 뒤 Variables 에 `DEPLOY_ENABLED=true` ([deploy.md](deploy.md)) |

## 3단계 — 🌐 웹에서 확인

이슈를 하나 만들어 `claude` 라벨을 붙여 본다. 예: "사용자 목록에 총 인원 수 표시".

10분 안에 PR 과 리뷰 코멘트가 달리면 설정이 끝난 것이다. 기다리기 싫으면 이슈 훑기를 바로 돌린다.

```bash
gh workflow run claude-dispatch.yml
```

이슈 잘 쓰는 법과 라벨 고르는 기준은 [issue-guide.md](issue-guide.md).

## 안 될 때

**처음 켤 때 주로 겪는 것**

| 증상 | 확인할 곳 |
|---|---|
| 이슈에 라벨을 붙여도 아무 일이 없다 | 라벨 철자, Actions 탭에 claude-dispatch 가 돌았는지, `AGENT_PAT` 등록 여부 |
| PR 은 생겼는데 리뷰가 안 달린다 | `AGENT_PAT` — 기본 토큰으로 만든 PR 은 워크플로를 깨우지 못한다 |
| push 나 PR 생성이 실패한다 | 2단계의 워크플로 권한, PAT 의 Contents · Pull requests 권한 |
| Claude 실행 단계에서 인증 오류 | `CLAUDE_CODE_OAUTH_TOKEN` 재발급. `ANTHROPIC_API_KEY` 를 함께 등록하면 API 로 과금되니 같이 두지 않는다 |

**쓰다가 겪는 것**

| 증상 | 확인할 곳 |
|---|---|
| 리뷰는 통과했는데 자동 머지가 안 된다 | 정상일 수 있다 — 자동 머지는 에이전트가 쪼갠 하위 이슈(`claude-made` 라벨)에만 적용된다. 사람이 올린 이슈는 사람이 머지한다 |
| 지적을 받았는데 스스로 고치지 않는다 | `AGENT_PAT` 의 **Actions: Read and write** 권한 |
| 그래프의 다음 단계가 안 돈다 | 앞 단계가 실패했는지 본다. 실패했다면 멈추는 것이 정상 동작이다 |
| `순차 단계는 최대 4개예요` 에러 | `CLAUDE_GRAPH` 에서 `>` 로 이은 단계가 4개를 넘었다 — `+` 로 묶어 동시에 돌리거나 작업을 두 번에 나눈다 |

## 4단계 (선택) — 스펙 먼저 쓰기 켜기

이슈 대신 스펙 문서를 먼저 쓰고 그 스펙으로 구현하는 방식이다. **켜지 않아도 된다** — 위 3단계까지로 쓰는 데 지장이 없다.

준비물이 하나 더 필요하다(`uv`). 켜는 법과 판단 기준은 [sdd-guide.md](sdd-guide.md) 에 있다.

```bash
bash .github/agent/setup-speckit.sh
```

## 켠 다음 — 어디서 무엇을 바꾸나

원칙은 하나다: **스위치와 비밀값은 🌐 웹에서, 동작의 내용은 💻 저장소 파일을 고쳐 커밋한다.**

### 🌐 웹 (GitHub)

| 위치 | 바꿀 수 있는 것 |
|---|---|
| Settings → Secrets and variables → Actions | 토큰 2개(필수) · 배포 시크릿 · `DEPLOY_ENABLED` 변수 |
| Actions → claude-dispatch | 이슈 자동 착수 끄기·켜기(워크플로 비활성화), 즉시 실행 |
| Issues → Labels | `claude` = 에이전트에게 맡김, `claude-split` = 쪼개서 맡김, `claude-sent` 를 떼면 처음부터 다시 |
| PR 머지 버튼 | 사람이 올린 이슈의 PR 은 사람 몫 — 에이전트가 쪼갠 하위 이슈는 리뷰 통과 시 자동 머지 |

### 💻 저장소 파일 (로컬에서 고쳐 커밋)

| 파일 | 바꿀 수 있는 것 |
|---|---|
| `.github/agent/settings.env` | 그래프 모양(`CLAUDE_GRAPH`), 재수정 횟수, 러너·런타임 버전, 리뷰 통과 기준 |
| `.github/agent/nodes/<이름>.md` | 노드별 역할 지시문, 새 노드 추가 |
| `common/docs/code-review/rules.md` | 리뷰 규칙 — MUST(머지 차단) / SHOULD(참고 코멘트) |
| `.claude/skills/` (공통) · `backend/.claude/skills/` · `frontend/.claude/skills/` | 코딩 규칙 — 일꾼과 리뷰어가 자동으로 읽는다 |

나머지 워크플로 파일은 설정이 아니라 기능 자체를 개조할 때만 연다 ([.github/README.md](../.github/README.md)).

**설정 파일은 항상 기본 브랜치의 것이 쓰인다.** 작업 브랜치에서 고쳐도 그 작업에는 반영되지 않는다.

에이전트가 자기 규칙을 스스로 바꾸지 못하게 하려는 것이다. 설정을 바꾸려면 main 에 머지한다.

---

동작 방식과 설정은 [agent-guide.md](agent-guide.md).
