# Claude 코딩 에이전트 템플릿 (Kotlin + Spring Boot / React)

> **이 문서는 사람이 읽습니다.** 에이전트가 읽는 규칙은 [CLAUDE.md](CLAUDE.md)·[AGENTS.md](AGENTS.md) 입니다.

이슈를 쓰면 에이전트가 코드를 만들고, 리뷰까지 마친 PR 을 연다. 사람은 두 가지만 한다 —
무엇을 만들지 쓰기, **직접 올린 이슈**의 PR 머지하기. 에이전트가 쪼갠 하위 이슈의 PR 은
리뷰를 통과하면 자동으로 머지된다.

## 시작하기 (처음 한 번, 15분)

**1. 저장소 올리기**

```bash
git init && git add -A && git commit -m "chore:템플릿 초기화"
git branch -M main
git remote add origin <저장소 주소> && git push -u origin main
```

**2. 에이전트 켜기**

[docs/setup.md](docs/setup.md) 대로 토큰 두 개를 발급해 스크립트를 한 번 실행한다. 파일은 고칠 게 없다.

```bash
CLAUDE_CODE_OAUTH_TOKEN=<발급값> AGENT_PAT=<PAT> bash .github/agent/setup-agent.sh
```

**3. 백엔드 뼈대 만들기**

[backend/README.md](backend/README.md) 대로 `backend/` 안에 Spring 멀티모듈 템플릿을 채우고 커밋한다.

**4. 프론트엔드 확인**

```bash
cd frontend && cp .env.example .env && npm install && npm run dev
```

완성된 앱이 들어 있어 바로 뜬다.

**5. 첫 구축 지시**

[TASK.md](TASK.md) 의 빈칸을 채워 커밋하고, 워크플로를 한 번 호출한다.

```bash
gh workflow run claude-agent.yml -f prompt="@TASK.md" -f graph="api>web>e2e"
```

백엔드 API → 프론트 화면 → E2E 테스트가 차례로 만들어지고 PR 이 열린다. 리뷰 통과를
확인하고 머지하면 끝이다. 상세는 [docs/agent-guide.md](docs/agent-guide.md).

## 그다음부터

이슈를 쓰고 `claude` 라벨을 붙인다. 그게 전부다. 큰 작업은 `claude-split` 라벨을 붙이면
하위 이슈로 쪼개서 진행한다. 이슈 잘 쓰는 법은 [docs/issue-guide.md](docs/issue-guide.md).

    이슈 + claude 라벨
      → 에이전트가 코딩 → PR → 에이전트가 리뷰
      → 지적이 있으면 스스로 수정 (최대 3회)
      → 사람이 올린 이슈: 사람이 확인 후 머지
        에이전트가 쪼갠 하위 이슈: 리뷰 통과 시 자동 머지

main 에 머지되면 GHCR 이미지 배포까지 이어진다 ([docs/deploy.md](docs/deploy.md)).

## 폴더와 파일 — 어디를 보면 되나

**사람이 읽는 것**

    README.md    지금 이 문서
    docs/        사용 설명서 — 읽는 순서는 docs/README.md
    TASK.md      첫 구축 명세 양식 (빈칸을 채워 쓴다)

**사람이 고치는 설정** — 동작을 바꾸고 싶을 때는 이 세 곳이 전부

    .github/agent/settings.env       그래프 모양·재수정 횟수·런타임·리뷰 기준
    .github/agent/nodes/             각 노드의 역할 지시문 (노드당 파일 하나)
    common/docs/code-review/rules.md 리뷰 규칙 (MUST = 머지 차단)

**에이전트가 읽고 쓰는 것** — 사람은 몰라도 된다

    CLAUDE.md · AGENTS.md   에이전트 작업 규칙 진입점
    .claude/                공통 코딩 규칙 (ponytail, 객체지향 설계)
    backend/.claude/        백엔드 규칙 (kotlin-* 계층 스킬 9종)
    frontend/.claude/       프론트엔드 규칙 (frontend-react)
    CONTRACT.md             백엔드가 기록하는 API 계약 (프론트가 읽는다)
    .github/workflows/      CI 잡 본체 — 기능 개조 때만 연다 ([안내](.github/README.md))

**앱 코드**

    backend/            백엔드 앱 자리 — Spring 멀티모듈 뼈대로 채운다
    frontend/           프론트엔드 앱 — 완성 상태로 동봉
    docker-compose.yml  서버 배포용

## 코드 규칙 요약

| | |
|---|---|
| 백엔드 레이어 | Controller → Domain Service → Implement → Repository, 단방향 |
| 프론트 레이어 | pages → hooks → services → api → lib, 단방향 |
| 컨트롤러 | 요청·응답 변환과 인증 정보 추출만 |
| 도메인 서비스 | 유스케이스 조립과 트랜잭션 경계 |
| 구현 레이어 | `TodoFinder`·`TodoAppender` 처럼 재사용 단위 |
| 저장소 | `storage:db-core` 로 격리, 엔티티는 밖으로 안 나간다 |
| 자료형 | 타입 명시 필수, `Any`·`!!`·`any` 금지 |
| 불변성 | 세터 금지. 엔티티는 `private set` + 행위 메서드로만 변경 |
| 주석 | 규칙 예외·특이사항에만 |
| 테스트 | 새 동작마다 유닛 테스트 동반, 한 메서드는 한 기능만 검증 |

전체는 각 모듈의 `.claude/skills/` 에 있다.

## 무엇이 궁금하면 어디로

| 하고 싶은 것 | 볼 문서 |
|---|---|
| 처음 켜기 (한 번, 15분) | [docs/setup.md](docs/setup.md) |
| 일 시키기 — 이슈 쓰는 법, 라벨 고르기 | [docs/issue-guide.md](docs/issue-guide.md) |
| 동작 원리 알기, 설정 바꾸기 | [docs/agent-guide.md](docs/agent-guide.md) |
| 서버 배포 붙이기 | [docs/deploy.md](docs/deploy.md) |
| 백엔드 뼈대 만들기 | [backend/README.md](backend/README.md) |
| 프론트엔드 구조 | [frontend/README.md](frontend/README.md) |
| CI 파일이 뭐가 뭔지 | [.github/README.md](.github/README.md) |
| 팀 리뷰 규칙 추가 | `common/docs/code-review/rules.md` 에 MUST 로 적는다 |
