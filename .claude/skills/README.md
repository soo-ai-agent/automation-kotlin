# 공통 코딩 규칙 스킬

> **이 폴더는 에이전트가 읽습니다.** 스택과 무관하게 모든 코드에 적용되는 규칙입니다.

스택별 규칙은 각 모듈에 있다 — 백엔드 [backend/.claude/skills/](../../backend/.claude/skills/),
프론트엔드 [frontend/.claude/skills/](../../frontend/.claude/skills/).
어떤 규칙이 적용될지는 **고치는 파일의 위치**가 정한다.

| 스킬 | 무엇을 다루나 | 언제 |
|---|---|---|
| [ponytail](ponytail/SKILL.md) | 가장 게으른 해법 — YAGNI, 표준 라이브러리 우선, 가장 짧은 diff | 모든 코딩 작업 |
| [ponytail-review](ponytail-review/SKILL.md) | diff 에서 오버엔지니어링만 골라내는 리뷰 | "뭘 지울 수 있어?" |
| [ponytail-audit](ponytail-audit/SKILL.md) | 저장소 전체 오버엔지니어링 감사 | "이 저장소에서 뭘 덜어낼 수 있어?" |
| [ponytail-debt](ponytail-debt/SKILL.md) | `ponytail:` 주석을 모아 만든 부채 장부 | "미뤄둔 게 뭐야?" |
| [oop-responsibility-design](oop-responsibility-design/SKILL.md) | 책임주도 설계 — 책임 배치, 다형성, 캡슐화, GRASP | "이 로직을 어느 클래스에 두나" |

`oop-responsibility-design` 은 두 문서로 나뉜다.

- **[SKILL.md](oop-responsibility-design/SKILL.md)** (151줄) — 규칙 요약. 코드 작성·리뷰 판단에는 이것만으로 충분하다.
- **[reference.md](oop-responsibility-design/reference.md)** (787줄) — 영화 예매 도메인 코틀린 예제로
  절차적 코드가 객체지향으로 바뀌는 8단계를 따라간다. 설계 근거를 설명하거나 개념을 배울 때 읽는다.

## 라이선스

[LICENSE](LICENSE) (MIT, © DietrichGebert) 는 **`ponytail*` 스킬 4종에만** 적용된다 —
각 파일의 frontmatter `license: MIT` 로도 표시되어 있다.

`oop-responsibility-design` 은 이 저장소의 자체 문서이며 LICENSE 적용 대상이 아니다.
