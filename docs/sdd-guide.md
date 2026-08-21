# 스펙 먼저 쓰기 (SDD) — 선택 기능

> **이 문서는 사람이 읽습니다.**

이슈 대신 **스펙 문서를 먼저 쓰고, 그 스펙으로 구현**하는 방식이다. [spec-kit](https://github.com/github/spec-kit) 을 이 저장소에 얹어서 쓴다.

**선택 사항이다.** 켜지 않아도 기존 흐름(이슈 + `claude` 라벨)은 그대로 돌아간다. 켜도 기존 흐름이 사라지지 않는다.

## 켤지 말지

큰 기능을 여럿이 나눠 만들 때, 또는 "만들고 보니 원하던 게 아니었다" 가 반복될 때 쓴다. 요구사항을 글로 먼저 고정하고 그 글을 고쳐 가며 합의하는 방식이라, 합의 비용을 앞으로 당긴다.

버그 수정이나 작은 변경에는 쓰지 않는다. 단계가 늘어난 만큼 시간과 토큰을 더 쓰기 때문에, 이슈 한 줄로 끝날 일에는 손해다.

## 켜기

준비물은 [uv](https://docs.astral.sh/uv/getting-started/installation/) 하나다. 없으면 스크립트가 설치 방법을 알려주고 멈춘다.

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh   # uv 가 없을 때만
bash .github/agent/setup-speckit.sh
```

한 번 돌리면 도구 설치, 저장소 초기화, 한국어 템플릿 등록, 확인까지 끝난다. 여러 번 다시 돌려도 안전하다.

처음 돌리면 **그 시점의 최신 릴리스**로 버전이 정해지고 `common/speckit-ko/speckit-version.txt` 에 적힌다. **이 파일을 커밋한다.** 그래야 나중에 clone 한 사람도 같은 버전을 받는다.

## 무엇이 어디에 생기나

| 자리 | 무엇 | 커밋하나 |
|---|---|---|
| `specs/` | 만든 스펙·계획·작업 목록 | **한다** — 이게 결과물이다 |
| `common/speckit-ko/speckit-version.txt` | 이 프로젝트가 쓰는 spec-kit 버전 | **한다** |
| `.specify/memory/constitution.md` | 프로젝트 헌법 — `/speckit-constitution` 이 만든다 | **한다** — 우리가 쓴 규칙이다 |
| `.specify/` 의 나머지 | spec-kit 설치물 | 안 한다 (`.gitignore`) |
| `.claude/skills/speckit-*/` | `/speckit-*` 명령 10종 | 안 한다 (`.gitignore`) |

`speckit-*` 스킬은 **우리 규칙 스킬과 같은 폴더**에 깔린다. 이름 앞자리로 구분되고 커밋되지 않지만, 스킬 목록을 보면 섞여 보인다.

## 쓰는 순서

| 명령 | 언제 | 결과 |
|---|---|---|
| `/speckit-constitution` | 맨 처음 한 번 | 프로젝트 규칙을 정한다 |
| `/speckit-specify` | 만들 것이 정해졌을 때 | `specs/<번호-이름>/spec.md` |
| `/speckit-clarify` | 스펙에 모호한 곳이 있을 때 (선택) | 질문으로 좁혀 스펙 보강 |
| `/speckit-plan` | 스펙이 굳었을 때 | `plan.md` — 기술 맥락과 구조 결정 |
| `/speckit-tasks` | 계획이 섰을 때 | `tasks.md` — 스토리별 작업 목록 |
| `/speckit-analyze` | 구현 직전 (선택) | 스펙·계획·작업이 서로 어긋나는지 검사 |
| `/speckit-implement` | 마지막 | 작업 목록대로 구현 |

나머지 셋은 필요할 때만 쓴다 — `/speckit-checklist` 는 요구사항 품질 검토 체크리스트를 만들고, `/speckit-converge` 는 이미 짜인 코드와 스펙을 대조해 남은 작업을 `tasks.md` 에 덧붙이며, `/speckit-taskstoissues` 는 작업 목록을 GitHub 이슈로 바꾼다.

`/speckit-constitution` 은 **규칙을 새로 쓰는 자리가 아니다.**

이 저장소의 규칙은 이미 `.claude/skills/` 와 `common/docs/code-review/rules.md` 에 있으므로, constitution 은 그것들을 **가리키게** 쓴다.

규칙을 복사해 넣으면 같은 규칙을 말하는 문서가 둘이 되어 서로 어긋난다.

여기에 **"산출물은 한국어로 작성한다"** 를 넣는다. spec-kit 에는 출력 언어 설정이 없어서, 이 지시가 유일한 수단이다.

## 기존 흐름과 어떻게 만나나

**스펙은 로컬에서 만들고, 구현은 기존대로 한다.**

CI 노드(GitHub Actions)는 spec-kit 을 쓰지 않는다 — 노드가 쓸 수 있는 명령이 `git`·`gradle`·`npm` 으로 제한돼 있어서 `/speckit-*` 를 돌릴 수 없다.

이 제한은 일부러 좁혀 둔 것이라 넓히지 않는다.

그래서 이렇게 나눈다.

    💻 로컬(사람)  /speckit-* 로 스펙을 만들고 specs/ 에 커밋
    🌐 CI(노드)    커밋된 specs/ 를 읽어 구현

이슈를 쓸 때 본문에 스펙 경로(`specs/003-주문취소/spec.md`)를 적으면, 노드가 그 문서를 읽고 작업한다.

기존 문서와 겹치는 부분은 아래처럼 나눠 쓴다.

| 문서 | 언제 쓰나 |
|---|---|
| `TASK.md` | 맨 처음 저장소를 구축할 때 한 번 (SDD 와 무관) |
| `specs/` | 그 뒤에 기능을 추가할 때 — SDD 를 켰다면 |
| 이슈 본문 | SDD 를 켜지 않았거나, 작은 변경일 때 |
| `CONTRACT.md` | API 계약 — `api` 노드가 쓰고 `web` 노드가 읽는다. SDD 와 무관하게 그대로다 |

## 결과가 스펙과 다르면

**코드를 직접 고치지 말고 스펙으로 돌아간다.** `/speckit-specify` 를 다시 불러 스펙을 고친 뒤 아래 단계를 다시 돌린다.

코드만 고치면 스펙과 코드가 갈라지고, 다음 사람이 어느 쪽을 믿어야 할지 알 수 없게 된다. 스펙이 기준이라는 것이 이 방식의 전부다.

## 산출물에 영어가 섞여 있는 이유

템플릿은 한국어로 번역돼 있지만 일부 표식은 영어로 남겼다. `/speckit-*` 명령이 그 문자열을 문자 그대로 찾아 읽고 채우기 때문에, 한국어로 바꾸면 단계 사이 연결이 조용히 끊긴다.

| 영어로 남은 것 | 뜻 |
|---|---|
| `[NEEDS CLARIFICATION]` | 아직 정해지지 않아 물어봐야 하는 자리 |
| `FR-001`, `SC-001`, `CHK001`, `T001` | 요구사항·성공기준·체크·작업 번호 |
| `P1`/`P2`/`P3`, `US1` | 우선순위, 사용자 스토리 번호 |
| `[P]` | 병렬로 해도 되는 작업 |
| `**Given** / **When** / **Then**` | 시나리오의 "이런 상태에서 / 이렇게 하면 / 이렇게 된다" |

절 제목은 `## Requirements (요구사항)` 처럼 영어와 한국어를 나란히 적었다. 명령은 영어로 찾고 사람은 한국어로 읽는다.

## 버전 올리기

```bash
SPECKIT_VERSION=latest bash .github/agent/setup-speckit.sh
```

올리기 전에 [common/speckit-ko/README.md](../common/speckit-ko/README.md) 의 "갱신 절차" 를 읽는다.

한국어 템플릿이 기본 템플릿을 이기는 구조라, 상류가 개선돼도 **경고 없이 그 개선이 가려진다.** 번역 기준과 설치 버전이 다르면 스크립트가 알려 주므로, 그때 상류 변경분을 확인해 번역에 반영한다.

## 끄기

**`.specify/` 를 통째로 지우면 커밋해 둔 헌법까지 사라진다.** 헌법을 남기려면 그것만 빼고 지운다.

```bash
find .specify -mindepth 1 -maxdepth 1 ! -name memory -exec rm -rf {} +
rm -rf .specify/memory/.constitution-template.json .claude/skills/speckit-*
uv tool uninstall specify-cli
```

헌법도 버릴 거라면 `rm -rf .specify .claude/skills/speckit-*` 로 한 번에 지운다. 커밋에서도 빠지므로 되돌리려면 git 으로 되살려야 한다.

`specs/` 와 `common/speckit-ko/` 는 어느 쪽이든 남는다. 지우려면 직접 지운다. 기존 이슈 흐름은 영향받지 않는다.
