# spec-kit 한국어 프리셋

> **이 폴더는 사람과 에이전트가 함께 읽습니다.** 설치물이 아니라 **우리 자산**이라서 저장소에 커밋합니다.

[spec-kit](https://github.com/github/spec-kit) 이 만드는 산출물(`spec.md`·`plan.md`·`tasks.md`·체크리스트)의 템플릿을 한국어로 바꾼 것이다.

**쓰는 법은 [docs/sdd-guide.md](../../docs/sdd-guide.md) 에 있다.** 이 문서는 그 아래에서 번역이 어떻게 유지되는지를 다룬다.

`.github/agent/setup-speckit.sh` 가 이 폴더를 `specify preset add --dev` 로 등록하면, spec-kit 이 `.specify/presets/korean/` 에 설치한다. 손으로 옮길 일은 없다.

**이 폴더를 고쳤으면 설치 스크립트를 다시 돌려야 반영된다.** 등록은 복사라서, 원본만 고치고 커밋하면 실제로 쓰이는 것은 예전 번역이다.

```bash
bash .github/agent/setup-speckit.sh
```

## 번역 범위 — 사람이 읽는 것만

| 대상 | 번역 | 이유 |
|---|---|---|
| 산출물 템플릿 4종 (이 폴더) | O | 사람이 검토하는 `spec.md`·`plan.md`·`tasks.md` 의 모양을 정한다 |
| 명령 스킬 10종 (`speckit-*`) | X | 에이전트만 읽는다. 분량이 6배(약 18,000단어)이고 상류에서 자주 바뀐다 |

명령 스킬은 상류 저장소의 `templates/commands/` 가 설치 시점에 `.claude/skills/speckit-*/SKILL.md` 로 깔린 것이다.

`/speckit-specify` 처럼 하이픈으로 부른다. **우리 규칙 스킬과 같은 폴더에 깔리므로** `.gitignore` 가 `speckit-*` 이름으로 걸러 낸다.

산출물이 한국어로 나오게 하는 것은 번역이 아니라 `constitution.md` 의 지시가 맡는다 — spec-kit 에 출력 언어 설정은 없다.

## 무엇을 영어로 남겼나

명령 스킬이 이 문자열들을 찾아 읽고 채운다. 한국어로 바꾸면 단계 사이 연결이 조용히 끊긴다.

- 치환 토큰 — `__SPECKIT_COMMAND_PLAN__` 처럼 설치 시점에 실제 명령 이름으로 바뀌는 자리

- 식별자 — `FR-001`, `SC-001`, `CHK001`, `T001`, `US1`, `P1`/`P2`/`P3`, `[P]`

- 상태 표식 — `[NEEDS CLARIFICATION]`, `Draft`

- BDD 낱말 — `**Given**`, `**When**`, `**Then**`

- 자리표시자 — `[FEATURE NAME]`, `[###-feature-name]`, `[DATE]`, `$ARGUMENTS`

**절 제목은 영어와 한국어를 나란히 적었다** (`## Requirements (요구사항)`). 명령 스킬이 영어 제목으로 절을 찾고, 사람은 한국어로 읽는다.

스크립트는 마크다운을 파싱하지 않으므로(`scripts/bash/common.sh` 는 JSON·YAML 만 읽는다) 이 병기가 스크립트를 깨뜨리지 않는다.

## 상류 기준점

번역은 아래 시점의 원문을 옮긴 것이다. 버전을 올릴 때 이 해시부터의 변경만 확인하면 된다.

| 템플릿 | 기준 커밋 | 원문 날짜 |
|---|---|---|
| `spec-template.md` | `c6afe4c` | 2026-05-28 |
| `plan-template.md` | `87a9690` | 2026-07-10 |
| `tasks-template.md` | `c6afe4c` | 2026-05-28 |
| `checklist-template.md` | `bd04776` | 2026-08-12 |

이 번역이 기준으로 삼은 릴리스는 `translated-against.txt` 에 적혀 있다. 번역을 갱신한 사람이 위 표와 그 파일을 함께 고친다.

## 갱신 절차 — 버전을 올릴 때 반드시 한다

**오버라이드는 기본 템플릿을 이긴다.** 그래서 상류가 개선돼도 우리 번역이 계속 이기고, **아무 경고 없이 그 개선을 못 받는다.**

덮어쓰기는 시끄럽지만 가림은 조용하다. 그래서 버전을 올릴 때 아래를 한다.

```bash
git clone --filter=blob:none https://github.com/github/spec-kit.git /tmp/spec-kit
cd /tmp/spec-kit
git log <위 표의 기준 커밋>..<올릴 태그> -- templates/spec-template.md
```

0건이면 그대로 두고, 변경이 있으면 그 부분만 번역에 반영한 뒤 위 표의 해시를 갱신한다. 전체를 다시 번역하는 일이 아니다.

최근 3개월 기준으로 이 템플릿 4종은 실질 변경이 한 건뿐이었다(2026-08-12 체크리스트). 같은 기간 명령 스킬은 21회 바뀌었고, 그쪽은 번역하지 않으므로 자동으로 최신을 따른다.

## 버전을 정하는 방식 — 시작할 때의 최신으로 고정

**템플릿을 받아 프로젝트를 시작하는 시점의 최신 릴리스**를 쓴다. 여기 박아 둔 버전이 몇 달 뒤 낡은 채로 깔리지 않게 하기 위해서다.

동시에 **한 번 정해지면 고정된다.** 사람마다 다른 파이프라인이 깔리면 같은 스펙이 다르게 처리되기 때문이다. 둘을 함께 만족시키는 방법은 파일 하나다.

| 파일 | 무엇 | 누가 정하나 |
|---|---|---|
| `speckit-version.txt` | 이 프로젝트가 쓰는 spec-kit 버전 | 첫 설치 때 스크립트가 그 시점 최신으로 적는다 — **커밋한다** |
| `translated-against.txt` | 위 번역이 기준 삼은 릴리스 | 번역을 갱신한 사람이 고친다 |

`speckit-version.txt` 는 첫 설치 때 생기는 파일이다. 커밋하면 그다음부터 clone 한 사람은 모두 같은 버전을 받는다.

```bash
bash .github/agent/setup-speckit.sh                           # 처음: 최신을 찾아 고정
SPECKIT_VERSION=latest bash .github/agent/setup-speckit.sh    # 올릴 때: 최신으로 다시 고정
SPECKIT_VERSION=v0.17.0 bash .github/agent/setup-speckit.sh   # 특정 버전으로
```

셋 중 무엇으로 돌리든 실제로 설치한 버전이 `speckit-version.txt` 에 적힌다. 그래서 올린 버전이 다음 실행에 되돌아가지 않는다.

두 파일의 값이 다르면 스크립트가 경고한다 — 설치할 버전이 번역 기준과 어긋난다는 뜻이고, 위 갱신 절차를 밟으라는 신호다.

**옵션 이름은 버전마다 다르다.** `--non-interactive` 는 v0.16.5 에 있고 v0.16.4 에는 없다. 최신을 따라가는 방식이라 스크립트가 `specify init --help` 를 보고 있는 옵션만 골라 붙인다.

그래도 초기화가 실패하면 그 버전의 옵션이 더 달라진 것이니, 스크립트가 알려 주는 대로 `SPECKIT_VERSION=latest` 로 다시 고정하거나 실패한 명령을 직접 돌려 확인한다.

## 왜 `.specify/` 안에 두지 않나

`.specify/` 는 spec-kit 이 설치·갱신하는 폴더라 `.gitignore` 대상이다. 번역본을 그 안에 두면 무시 규칙에 함께 걸려 사라진다.

원본을 여기 두고 설치할 때 등록하면, 재설치할 때마다 번역이 다시 적용되고 소유도 분명해진다.

## 검증한 것 (2026-08-21)

빈 저장소 사본에서 확인한 것들이다.

- `specify preset add --dev` 로 등록해 템플릿 4종이 모두 `korean v1.0.0` 으로 잡히는 것

- `specify init --here --force` 로 관리 파일을 다시 깔아도 4종 모두 한국어판이 그대로 이기는 것 — 위 갱신 절차가 전제하는 동작이다

- 설치 스크립트를 연속 3회 돌려 모두 성공하는 것 (재실행 안전)

- 버전 세 가지 방식(최신 자동 고정·`latest` 재고정·특정 버전 지정)이 모두 `speckit-version.txt` 에 반영되는 것

- 이전 버전(v0.16.4)에서도 옵션을 골라 붙여 통과하는 것

- 번역 기준과 설치 버전이 다를 때 경고가 나오는 것
