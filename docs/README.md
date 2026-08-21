# 문서 안내

> **이 문서는 사람이 읽습니다 — docs/ 전체가 사람 전용입니다.** 에이전트가 읽는 규칙은 루트 `CLAUDE.md`·`AGENTS.md`(진입점), 각 모듈의 `.claude/skills/`(코딩 규칙), `common/docs/`(리뷰 규칙·자동화 명세)에 있다.

**이 저장소가 처음이라면 [루트 README](../README.md) 부터 읽는다.** 이게 무엇인지, 용어가 무슨 뜻인지, 무엇을 준비해야 하는지가 거기에 있다.

사람은 **이슈 쓰기 → PR 머지** 두 가지만 한다. 나머지는 자동이다. 이 폴더의 문서는 읽는 순서대로 번호를 매겼다.

(선택 기능인 스펙 먼저 쓰기를 켜면 그 앞에 **스펙 쓰기**가 한 단계 붙는다 — 7번 문서.)

| # | 문서 | 언제 읽나 |
|---|---|---|
| 1 | [setup.md](setup.md) | 처음 켤 때 — 토큰 발급, 스크립트 한 번 (15분) |
| 2 | [issue-guide.md](issue-guide.md) | 일 시킬 때 — 라벨 고르기, 이슈 쓰는 법, 중간 개입 |
| 3 | [agent-guide.md](agent-guide.md) | 동작을 바꾸고 싶을 때 — 그래프·리뷰 루프·설정 위치 |
| 4 | [deploy.md](deploy.md) | 서버 배포를 붙일 때 |
| 5 | [ads.md](ads.md) | 앱에 광고를 넣을지 정할 때 — 판단 기준과 스토어 체크리스트 |
| 6 | [external-apis.md](external-apis.md) | 외부 시스템이 막혔을 때 — 무엇을 쓰고 있고 막히면 무엇이 대신 나가는지 |
| 7 | [sdd-guide.md](sdd-guide.md) | (선택) 이슈 대신 스펙을 먼저 쓰고 싶을 때 — 켜는 법과 쓰는 순서 |

1·2 만 읽어도 쓰는 데는 지장이 없다. 3 은 기본 동작을 바꾸고 싶어질 때, 7 은 큰 기능을 여럿이 나눠 만들 때 연다.

앱을 만드는 문서는 각 모듈에 있다 — [backend/README.md](../backend/README.md), [frontend/README.md](../frontend/README.md).

CI 파일 지도는 [.github/README.md](../.github/README.md).
