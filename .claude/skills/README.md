# 공통 코딩 규칙 스킬

> **이 폴더는 에이전트가 읽습니다.** 스택과 무관하게 모든 코드에 적용되는 규칙입니다.

스택별 규칙은 각 모듈에 있다 — 백엔드 [backend/.claude/skills/](../../backend/.claude/skills/README.md)(17종), 프론트엔드 [frontend/.claude/skills/](../../frontend/.claude/skills/README.md)(저장소 규칙 7종 + 벤더링된 Expo 공식 스킬 18종).

이 폴더의 스킬은 고치는 파일의 위치와 무관하게 **항상 함께 적용된다.** 위치는 그 위에 얹는 스택 스킬(`kotlin-*` · `frontend-*`)을 고른다.

| 스킬 | 무엇을 다루나 | 언제 |
|---|---|---|
| [core-principles](core-principles/SKILL.md) | **최상위 3대 원칙** — 단순함 최우선, 최소 수정·무파괴, 데이터의 흐름과 통제. 다른 모든 규칙이 종속된다 | 모든 코드·규칙 문서 작업 |
| [ponytail](ponytail/SKILL.md) | 가장 게으른 해법 — YAGNI, 표준 라이브러리 우선, 가장 짧은 diff | 모든 코딩 작업 |
| [ponytail-review](ponytail-review/SKILL.md) | diff 에서 오버엔지니어링만 골라내는 리뷰 | "뭘 지울 수 있어?" |
| [ponytail-audit](ponytail-audit/SKILL.md) | 저장소 전체 오버엔지니어링 감사 | "이 저장소에서 뭘 덜어낼 수 있어?" |
| [ponytail-debt](ponytail-debt/SKILL.md) | `ponytail:` 주석을 모아 만든 부채 장부 | "미뤄둔 게 뭐야?" |
| [oop-responsibility-design](oop-responsibility-design/SKILL.md) | 책임주도 설계 — 책임 배치, 다형성, 캡슐화, GRASP | "이 로직을 어느 클래스에 두나" |
| [md-doc](md-doc/SKILL.md) | 이슈 분석·기술 문서 작성 — 쉬운 한국어, 비유 금지, 코드 인용, 결론 우선 | md 문서를 쓰거나 고칠 때 |
| [api-contract](api-contract/SKILL.md) | 서버-클라이언트 계약 — CONTRACT.md 미러링, nullable 대칭, enum 정규화, 와이어 단위 | API 타입·DTO·필드를 추가·변경할 때 |

`ponytail` 계열은 해법을 줄이는 스킬이지 규칙을 줄이는 스킬이 아니다 — 리뷰 규칙의 MUST(`common/docs/code-review/rules.md`)는 ponytail 로도 생략할 수 없다.

`oop-responsibility-design` 은 두 문서로 나뉜다.

- **[SKILL.md](oop-responsibility-design/SKILL.md)** — 규칙 요약. 코드 작성·리뷰 판단에는 이것만으로 충분하다.

- **[reference.md](oop-responsibility-design/reference.md)** — 영화 예매 도메인 코틀린 예제로 절차적 코드가 객체지향으로 바뀌는 8단계를 따라간다. 설계 근거를 설명하거나 개념을 배울 때만 읽는다.

## 스킬을 고치면 무엇이 검사하나

스킬은 고쳐도 아무것도 실패하지 않는다. 컴파일도 테스트도 스킬 문서를 읽지 않아서, 이름이 폴더와 어긋나거나 링크가 깨져도 조용히 지나간다.

그래서 `.claude/hooks/review-skill-edit.sh` 를 걸어 두었다. 에이전트가 Write·Edit 도구로 `SKILL.md` 를 고치면 넷을 세고, 이어서 `skill-creator` 호출을 지시한다.

| 훅이 세는 것 | skill-creator 가 보는 것 |
|---|---|
| frontmatter `name` 이 폴더 이름과 같은가 | description 이 이 스킬을 써야 할 상황에서 실제로 걸리는가 |
| description 이 트리거를 잡을 만큼 있는가 | 구조·분량이 읽기에 맞는가 |
| `kotlin-*`·`frontend-*` 이면 '적발 신호'와 '체크리스트' 절이 있는가 | 겹치는 스킬과 경계가 갈리는가 |
| 문서 안 상대 링크가 실제로 있는가 | |

벤더링본(`expo/`·`speckit-*`)은 상류 사본이라 건너뛴다. 세션·스킬당 한 번만 말하므로, 같은 파일을 연달아 고쳐도 같은 말을 반복하지 않는다.

## 이 폴더에 `speckit-*` 이 보인다면

스펙 먼저 쓰기([docs/sdd-guide.md](../../docs/sdd-guide.md))를 켜면 `speckit-analyze`·`speckit-specify` 같은 스킬 10종이 **이 폴더에 함께 깔린다.**

그것들은 우리 규칙이 아니라 spec-kit 이 설치한 명령이다. `.gitignore` 가 `speckit-*` 이름으로 걸러 내므로 커밋되지 않고, 위 표에도 넣지 않는다.

지우려면 `rm -rf .claude/skills/speckit-*` 하면 되고, 설치 스크립트를 다시 돌리면 다시 생긴다.

## 라이선스

[LICENSE](LICENSE) (MIT, © DietrichGebert) 는 **`ponytail*` 스킬 4종에만** 적용된다 — 각 파일의 frontmatter `license: MIT` 로도 표시되어 있다.

원본은 <https://github.com/DietrichGebert/ponytail> 이고, 무엇을 가져왔는지는 [docs/upstream.md](../../docs/upstream.md) 에 정리돼 있다.

`oop-responsibility-design` 은 이 저장소의 자체 문서이며 LICENSE 적용 대상이 아니다.
