# 빌려온 것 — 원본과 출처

> **이 문서는 사람이 읽습니다.**

이 템플릿에는 밖에서 가져온 것이 둘 있다. 무엇을 가져왔고, 원본이 어디이며, 우리가 무엇을 바꿨는지 적는다.

가져온 것을 고칠 때는 **원본이 따로 있다는 것을 먼저 기억한다.** 상류가 바뀌면 우리 쪽도 따라가야 하고, 우리가 고친 것은 상류로 돌아가지 않는다.

## ponytail — 가장 게으른 해법을 강제하는 스킬

| | |
|---|---|
| 원본 | <https://github.com/DietrichGebert/ponytail> |
| 라이선스 | MIT (© DietrichGebert) — [.claude/skills/LICENSE](../.claude/skills/LICENSE) |
| 우리 자리 | `.claude/skills/ponytail`·`ponytail-review`·`ponytail-audit`·`ponytail-debt` |

에이전트가 **가장 단순하고 가장 짧은 해법**을 고르게 만드는 규칙 모음이다.

코드를 쓰기 전에 이 순서로 묻는다 — 이게 애초에 필요한가(YAGNI), 이미 있는 것을 재사용할 수 있나, 표준 라이브러리로 되나, 플랫폼 기능으로 되나, 이미 깔린 의존성으로 되나, 한 줄로 되나.

네 스킬의 역할은 이렇게 나뉜다.

| 스킬 | 하는 일 |
|---|---|
| `ponytail` | 코드를 쓸 때 적용하는 본체 |
| `ponytail-review` | diff 에서 오버엔지니어링만 골라내는 리뷰 — **코드 리뷰할 때 함께 본다** |
| `ponytail-audit` | 저장소 전체를 훑는 일회성 감사 |
| `ponytail-debt` | 코드에 남은 `ponytail:` 주석을 모아 부채 장부로 만든다 |

**우리가 바꾼 것은 없다.** 원본 그대로 두었고, 각 파일 frontmatter 의 `license: MIT` 로 출처가 표시돼 있다.

`.claude/skills/LICENSE` 는 **이 네 스킬에만** 적용된다. 같은 폴더의 다른 스킬(`oop-responsibility-design`·`algorithm-implementation`·`md-doc`)은 이 저장소의 자체 문서다.

## spec-kit — 스펙 먼저 쓰기(SDD) 도구

| | |
|---|---|
| 원본 | <https://github.com/github/spec-kit> |
| 라이선스 | MIT (© GitHub, Inc.) |
| 쓰는 버전 | `common/speckit-ko/speckit-version.txt` 가 고정한다 |
| 우리 자리 | 설치물은 `.specify/`·`.claude/skills/speckit-*`(둘 다 커밋 안 함), 번역은 `common/speckit-ko/` |

만들 것을 **스펙 문서로 먼저 고정하고 그 스펙으로 구현**하게 돕는 도구다.

`/speckit-specify` → `/speckit-plan` → `/speckit-tasks` → `/speckit-implement` 순서로 문서를 만들어 가며, 산출물은 `specs/<기능>/` 에 쌓인다.

쓰는 법은 [sdd-guide.md](sdd-guide.md) 에 있다.

### 우리가 바꾼 것

**산출물 템플릿 4종을 한국어로 번역했다** (`spec`·`plan`·`tasks`·`checklist`). 사람이 검토하는 문서라서다. 프리셋으로 얹었기 때문에 상류를 업그레이드해도 번역이 남는다.

번역하지 않은 것은 명령 스킬 10종이다 — 에이전트만 읽고, 분량이 6배이며, 상류에서 자주 바뀐다.

`plan` 템플릿은 번역에 더해 **이 저장소의 모듈 구조**(Kotlin 멀티모듈·Expo 프론트)로 예시를 바꿨고, `tasks` 템플릿은 상류가 "테스트는 선택"이라고 한 부분을 **필수**로 고쳤다. 이 저장소에서는 테스트가 빠지면 머지가 막히기 때문이다.

무엇을 영어로 남겼는지, 상류가 바뀌었을 때 어떻게 따라가는지는 [common/speckit-ko/README.md](../common/speckit-ko/README.md) 에 있다.

### 주의

**번역본이 상류 템플릿을 이긴다.** 그래서 상류가 개선돼도 경고 없이 그 개선이 가려진다. 버전을 올릴 때 상류 변경분을 확인하는 절차가 프리셋 README 에 있고, 번역 기준과 설치 버전이 다르면 설치 스크립트가 알려준다.
