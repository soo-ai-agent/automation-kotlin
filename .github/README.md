# CI 안내

> **이 문서는 사람이 읽습니다.** 워크플로를 수정하려는 에이전트는 [common/docs/automation-spec.md](../common/docs/automation-spec.md) 를 읽습니다.

## 사람이 고치는 파일 (설정)

| 파일 | 무엇을 정하나 |
|---|---|
| [agent/settings.env](agent/settings.env) | 그래프 모양(`CLAUDE_GRAPH`), 재수정 횟수, 러너·런타임 버전, 리뷰 통과 기준 |
| [agent/nodes/](agent/nodes/) | 각 노드의 역할 지시문, 새 노드 추가 (노드당 파일 하나) |

리뷰 규칙은 [common/docs/code-review/rules.md](../common/docs/code-review/rules.md) 에 있다.

## 사람이 실행하는 파일 (처음 한 번)

| 파일 | 용도 |
|---|---|
| [agent/setup-agent.sh](agent/setup-agent.sh) | 라벨·시크릿·워크플로 권한·브랜치 보호 일괄 세팅 |

```bash
CLAUDE_CODE_OAUTH_TOKEN=<발급값> AGENT_PAT=<PAT> bash .github/agent/setup-agent.sh
```

## 건드리지 않는 파일 (기능 자체를 개조할 때만)

| 파일 | 역할 |
|---|---|
| [workflows/claude-dispatch.yml](workflows/claude-dispatch.yml) | 디스패처 — 라벨 이슈 감지·착수, 완료 후 정리(상위 이슈 완료 보고, 이슈·PR·브랜치 청소) |
| [workflows/claude-agent.yml](workflows/claude-agent.yml) | 진입점 — 그래프를 단계 잡(s1..s4)으로 펼쳐 노드들을 돌린다 |
| [workflows/claude-node.yml](workflows/claude-node.yml) | 노드 하나 — 코드 작성·커밋·push, 명세/하위 이슈/PR 생성 |
| [agent/graph.js](agent/graph.js) | `CLAUDE_GRAPH` 펼치기 (`>` 순차 · `+` 병렬 · `?` 수습) |
| [agent/stream.js](agent/stream.js) | 실행 로그 정리기 |
| [workflows/claude-review.yml](workflows/claude-review.yml) | 리뷰어 — PR diff 판정, 자동 머지, 재작업 트리거 |
| [workflows/deploy.yml](workflows/deploy.yml) | main 머지 시 빌드·배포 ([docs/deploy.md](../docs/deploy.md)) |

---

## GitLab 판과 다른 점

이 자동화의 원본은 GitLab CI 로 만들어졌고, 여기서는 GitHub Actions 로 옮겼다. 플랫폼 차이 때문에 구조가 달라진 곳은 셋이다.

| | GitLab | 여기 |
|---|---|---|
| 그래프 실행 | 자식 파이프라인을 잡마다 생성 | 단계 잡 s1..s4 를 **미리 선언**하고 매트릭스로 채운다 — Actions 는 잡을 실행 중에 만들 수 없다. 그래서 **순차 단계는 최대 4개**다 (병렬 수는 무제한) |
| 수습(`?`) | 별도 잡 + 아티팩트로 상태 전달 | **같은 잡 안에서** 이어 실행 — 잡을 두 벌씩 선언할 필요가 없고, 같은 브랜치를 이어받는다는 의미도 더 정확하다 |
| 노드 간 호출 | 트리거 토큰 | `AGENT_PAT`. **선택이 아니다** — 기본 `GITHUB_TOKEN` 으로 만든 PR·커밋은 다른 워크플로를 깨우지 못한다 |

권한 경계는 원본 그대로다: **Claude 는 파일만 쓰고, API 호출(이슈·PR·라벨)은 셸이 한다.** 그래서 `GH_TOKEN` 은 잡 전체가 아니라 `gh` 를 쓰는 step 에만 걸려 있다.

이 워크플로들을 **수정**하려면 먼저 [common/docs/automation-spec.md](../common/docs/automation-spec.md) 를 읽는다 — 요구사항·구현 위치·불변 조건이 정리되어 있다.
