# Claude 코딩 에이전트 템플릿 (Kotlin + Spring Boot / React Native)

> **이 문서는 사람이 읽습니다.** 에이전트가 읽는 규칙은 [CLAUDE.md](CLAUDE.md)·[AGENTS.md](AGENTS.md) 입니다.

## 이게 무엇인가

**만들 것을 글로 적어 두면, Claude 가 코드를 짜고 스스로 리뷰까지 마친 PR 을 열어 주는 저장소 템플릿**이다.

빈 저장소에 이 템플릿을 올리고 한 번만 설정하면, 그다음부터는 글만 써서 개발할 수 있다.

들어 있는 것은 넷이다.

- **자동화** — 이슈를 발견해 코드를 짜고, PR 을 열고, 리뷰하고, 지적을 스스로 고치는 GitHub Actions 워크플로 5개

- **스펙 먼저 쓰기(SDD)** — 새 기능은 `specs/` 에 스펙을 먼저 쓰고 그 스펙으로 구현한다. 산출물은 한국어로 나온다

- **코딩 규칙** — Claude 가 코드를 쓸 때와 리뷰할 때 따르는 규칙 문서 33종 (백엔드 17 · 프론트 8 · 공통 8)

- **앱 뼈대** — 바로 실행되는 Expo(React Native) 앱(iOS·Android·웹 한 코드)과, Spring 멀티모듈을 채워 넣을 백엔드 자리

사람이 하는 일은 둘뿐이다 — **무엇을 만들지 쓰기**, 그리고 **완성된 PR 을 머지할지 결정하기.**

## 먼저 알아둘 말 여섯 개

설명서 전체에 계속 나오는 말이다. 지금 외울 필요는 없고, 모르는 말이 나오면 여기로 돌아오면 된다.

| 말 | 뜻 |
|---|---|
| **에이전트** | 이 저장소에서 일하는 Claude 를 통틀어 부르는 말. 아래 셋으로 나뉜다 |
| **디스패처** | 10분마다 이슈 목록을 훑어보고, 라벨이 붙은 이슈를 찾아 일꾼을 부르는 워크플로 |
| **일꾼** | 실제로 브랜치를 만들어 코드를 쓰고, 커밋·push 하고, PR 을 여는 워크플로 |
| **리뷰어** | 열린 PR 의 변경 내용을 읽고 통과인지 수정 필요인지 판정하는 워크플로 |
| **노드** | 일꾼이 맡는 역할 하나. 8종이 있다 — `code`(구현) · `test`(검증) · `api`(백엔드) · `web`(프론트) · `e2e`(사용자 흐름 테스트) · `plan`(계획) · `split`(이슈 쪼개기) · `fix`(수습) |
| **그래프** | 노드를 어떤 순서로 이을지 정한 것. `plan>code>test` 처럼 쓴다 |

즉 **디스패처가 일을 발견해 일꾼에게 넘기고, 일꾼이 그래프에 적힌 노드 순서대로 코드를 만들고, 리뷰어가 그 결과를 판정한다.**

## 시작 전 준비물

| 준비물 | 확인할 것 |
|---|---|
| GitHub 저장소 | 비어 있어도 된다. 이 템플릿을 올릴 곳 |
| [gh CLI](https://cli.github.com) | 설치하고 `gh auth login` 까지 끝나 있어야 한다 |
| Node.js 20 이상 | 토큰 발급 도구와 프론트엔드(Expo) 실행에 쓴다 |
| Claude 구독 (Pro 또는 Max) | 에이전트가 Claude 를 실행하는 데 쓴다 |
| [uv](https://docs.astral.sh/uv/getting-started/installation/) | 스펙 먼저 쓰기 도구를 까는 데 쓴다 (5단계). 깔 수 없으면 스펙을 손으로 쓰는 길이 있다 ([안내](docs/sdd-guide.md#uv-를-깔-수-없는-환경이라면)) |
| JDK 25 | 백엔드를 **로컬에서** 돌릴 때만 필요하다. 나중에 준비해도 된다 |

## 시작하기 (처음 한 번)

**1. 저장소 올리기** — 에이전트는 GitHub 에 올라간 코드만 본다.

```bash
git init && git add -A && git commit -m "chore:템플릿 초기화"
git branch -M main
git remote add origin <저장소 주소> && git push -u origin main
```

**2. 에이전트 켜기** — 토큰 두 개를 발급해 스크립트를 한 번 돌린다. 라벨·시크릿·권한이 한꺼번에 설정된다.

```bash
CLAUDE_CODE_OAUTH_TOKEN=<발급값> AGENT_PAT=<PAT> bash .github/agent/setup-agent.sh
```

토큰 발급 방법과 각각이 왜 필요한지는 [docs/setup.md](docs/setup.md) 에 있다. 저장소 파일은 고칠 게 없다.

**3. 백엔드 뼈대 만들기** — `backend/` 는 지금 규칙 문서만 있는 빈 자리다. Spring 멀티모듈을 채워 커밋한다.

방법은 [backend/README.md](backend/README.md) 에 명령어까지 적혀 있다.

**4. 프론트엔드 확인** — 완성된 앱이 동봉돼 있어 바로 뜬다.

```bash
cd frontend && npm install && npm run web    # 브라우저로 확인 (폰으로 보려면 npm start 후 Expo Go 로 QR)
```

**5. 스펙 먼저 쓰기 켜기** — 새 기능을 만들 때 쓸 도구다. [uv](https://docs.astral.sh/uv/getting-started/installation/) 가 필요하고, 없으면 스크립트가 알려준다.

```bash
bash .github/agent/setup-speckit.sh
git add common/speckit-ko/speckit-version.txt && git commit -m "chore:spec-kit 버전 고정"
```

무엇이 깔리고 어떻게 쓰는지는 [docs/sdd-guide.md](docs/sdd-guide.md) 에 있다.

**6. 첫 구축 지시** — 첫 구축만은 스펙 대신 [TASK.md](TASK.md) 양식을 쓴다. 만들 것을 적고 **커밋해서 push 한 뒤** 한 번 호출한다. 워크플로는 GitHub 에 올라간 파일을 읽으므로 push 하지 않으면 빈 양식으로 돈다.

```bash
git add TASK.md && git commit -m "docs:구축 명세 작성" && git push
gh workflow run claude-agent.yml -f prompt="@TASK.md" -f graph="api>web>e2e"
```

`api>web>e2e` 는 "백엔드 API 를 만들고 → 그 API 에 맞춰 화면을 만들고 → E2E 테스트를 쓴다"는 뜻이다.

세 단계가 차례로 돌고 PR 이 하나 열린다. 리뷰 통과를 확인하고 머지하면 끝이다.

## 그다음부터 — 스펙을 쓰고 이슈로 넘긴다

**새 기능은 스펙을 먼저 쓴다.** `/speckit-specify` 로 만들 것을 `specs/` 에 적어 커밋하고, 이슈 본문에 그 경로를 적은 뒤 `claude` 라벨을 붙인다.

    스펙(specs/) → 이슈 + claude 라벨
      → 에이전트가 스펙을 읽고 코딩 → PR → 에이전트가 리뷰
      → 지적이 있으면 스스로 수정 (최대 3회)
      → 사람이 확인 후 머지

요구사항을 글로 먼저 고정해 "만들고 보니 원하던 게 아니었다"를 구현 전에 잡는 방식이다. 절차는 [docs/sdd-guide.md](docs/sdd-guide.md) 에 있다.

**버그 수정과 작은 변경은 스펙 없이 이슈 한 줄로 간다.** 무엇을 만들지에 이견이 생길 일이 없으면 스펙은 비용만 늘린다.

한 번에 하기엔 큰 작업이면 `claude` 대신 **`claude-split`** 라벨을 붙인다. 에이전트가 이슈를 독립적인 하위 이슈 2~6개로 쪼개서 각각 진행한다.

이때 하위 이슈의 PR 은 리뷰를 통과하면 **자동으로 머지된다.** 사람이 직접 올린 이슈의 PR 은 언제나 사람이 머지한다 — 만든 주체가 끝낸다는 원칙이다.

이슈를 잘 쓰는 법과 두 라벨을 고르는 기준은 [docs/issue-guide.md](docs/issue-guide.md) 에 있다.

**맡기지 않을 영역은 라벨을 붙이지 않으면 된다.** 디스패처는 라벨이 붙은 이슈만 집어간다.

main 에 머지되면 GHCR 이미지 배포까지 이어진다 ([docs/deploy.md](docs/deploy.md)).

## 폴더와 파일 — 어디를 보면 되나

**사람이 읽는 것**

    README.md    지금 이 문서
    docs/        사용 설명서 — 읽는 순서는 docs/README.md
    TASK.md      첫 구축 명세 양식 (빈칸을 채워 쓴다)
    bin/         내 컴퓨터에서 같은 규칙으로 Claude 를 여는 launcher (docs/local-claude.md)

**사람이 고치는 설정** — 동작을 바꾸고 싶을 때 열 곳 셋(settings.env·노드 지시문·리뷰 규칙)은 [.github/README.md](.github/README.md) 가 안내한다.

스펙 먼저 쓰기 쪽도 사람이 고치는 자리가 둘 있다 — `common/speckit-ko/`(한국어 산출물 템플릿)와 `.specify/memory/constitution.md`(프로젝트 헌법) ([안내](docs/sdd-guide.md)).

**에이전트가 읽고 쓰는 것** — 사람은 몰라도 된다. 독자별 문서 지도는 [docs/architecture.html](docs/architecture.html) 의 "문서 구조" 절에 있다.

**앱 코드**

    backend/            백엔드 앱 자리 — Spring 멀티모듈 뼈대로 채운다
    frontend/           프론트엔드 앱 — 완성 상태로 동봉
    docker-compose.yml  서버 배포용

## 어떤 코드가 나오나

에이전트는 아무렇게나 짜지 않는다. 코딩 규칙 스킬 33종을 따르도록 강제되고, 어기면 리뷰어가 머지를 막는다.

레이어 구조와 규칙 체계는 [docs/architecture.html](docs/architecture.html) 한 장에 그려져 있고, 규칙 전문은 각 모듈 `.claude/skills/` 의 색인(README)이 안내한다.

## 무엇이 궁금하면 어디로

| 하고 싶은 것 | 볼 문서 |
|---|---|
| 전체 구조를 한 장으로 | [docs/architecture.html](docs/architecture.html) — 브라우저로 연다 |
| 처음 켜기 (한 번) | [docs/setup.md](docs/setup.md) |
| 내 컴퓨터에서 같은 규칙으로 Claude 열기 | `claude-be` · `claude-fe` ([docs/local-claude.md](docs/local-claude.md)) |
| 일 시키기 — 이슈 쓰는 법, 라벨 고르기 | [docs/issue-guide.md](docs/issue-guide.md) |
| 동작 원리 알기, 설정 바꾸기 | [docs/agent-guide.md](docs/agent-guide.md) |
| 서버 배포 붙이기 | [docs/deploy.md](docs/deploy.md) |
| 광고를 넣을지 정하기 (스토어 체크리스트) | [docs/ads.md](docs/ads.md) |
| 새 기능의 스펙 쓰기 | [docs/sdd-guide.md](docs/sdd-guide.md) |
| 백엔드 뼈대 만들기 | [backend/README.md](backend/README.md) |
| 프론트엔드 구조 | [frontend/README.md](frontend/README.md) |
| CI 파일이 뭐가 뭔지 | [.github/README.md](.github/README.md) |
| 빌려온 것의 원본·라이선스 | [docs/upstream.md](docs/upstream.md) |
| 팀 리뷰 규칙 추가 | `common/docs/code-review/rules.md` 에 MUST 로 적는다 |
