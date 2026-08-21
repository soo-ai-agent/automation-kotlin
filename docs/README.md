# 문서 안내

> **이 문서는 사람이 읽습니다 — docs/ 전체가 사람 전용입니다.** 에이전트가 읽는 규칙은 루트 `CLAUDE.md`·`AGENTS.md`(진입점), 각 모듈의 `.claude/skills/`(코딩 규칙), `common/docs/`(리뷰 규칙·자동화 명세)에 있다.

**이 저장소가 처음이라면 [루트 README](../README.md) 부터 읽는다.** 이게 무엇인지, 용어가 무슨 뜻인지, 무엇을 준비해야 하는지가 거기에 있다.

사람은 **스펙 쓰기 → PR 머지** 두 가지만 한다. 나머지는 자동이다. 이 폴더의 문서는 읽는 순서대로 번호를 매겼다.

버그 수정처럼 합의할 것이 없는 일은 스펙 없이 이슈 한 줄로 간다 — 그때는 3번 문서를 본다.

| # | 문서 | 언제 읽나 |
|---|---|---|
| 1 | [setup.md](setup.md) | 처음 켤 때 — 토큰 발급, 스크립트 두 번 |
| 2 | [sdd-guide.md](sdd-guide.md) | 새 기능을 만들 때 — 스펙 쓰는 순서와 명령 |
| 3 | [issue-guide.md](issue-guide.md) | 이슈로 넘길 때 — 라벨 고르기, 이슈 쓰는 법, 중간 개입 |
| 4 | [agent-guide.md](agent-guide.md) | 동작을 바꾸고 싶을 때 — 그래프·리뷰 루프·설정 위치 |
| 5 | [deploy.md](deploy.md) | 서버 배포를 붙일 때 |
| 6 | [ads.md](ads.md) | 앱에 광고를 넣을지 정할 때 — 판단 기준과 스토어 체크리스트 |
| 7 | [external-apis.md](external-apis.md) | 외부 시스템이 막혔을 때 — 무엇을 쓰고 있고 막히면 무엇이 대신 나가는지 |
| 8 | [upstream.md](upstream.md) | 빌려온 것의 원본과 라이선스 — ponytail · spec-kit |

1~3 만 읽어도 쓰는 데는 지장이 없다. 4 는 기본 동작을 바꾸고 싶어질 때 연다.

앱을 만드는 문서는 각 모듈에 있다 — [backend/README.md](../backend/README.md), [frontend/README.md](../frontend/README.md).

CI 파일 지도는 [.github/README.md](../.github/README.md).
