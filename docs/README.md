# 문서 안내

> **이 문서는 사람이 읽습니다 — docs/ 전체가 사람 전용입니다.** 에이전트가 읽는 규칙은
>
> 루트 `CLAUDE.md`·`AGENTS.md`(진입점), 각 모듈의 `.claude/skills/`(코딩 규칙),
>
> `common/docs/`(리뷰 규칙·자동화 명세)에 있다.

사람은 **이슈 쓰기 → PR 머지** 두 가지만 한다. 나머지는 자동이다. 문서는 읽는 순서대로:

| # | 문서 | 언제 읽나 |
|---|---|---|
| 1 | [setup.md](setup.md) | 처음 켤 때 — 토큰 발급, 스크립트 한 번 (15분) |
| 2 | [issue-guide.md](issue-guide.md) | 일 시킬 때 — 라벨 고르기, 이슈 쓰는 법, 중간 개입 |
| 3 | [agent-guide.md](agent-guide.md) | 동작을 바꾸고 싶을 때 — 그래프·리뷰 루프·설정 위치 |
| 4 | [deploy.md](deploy.md) | 서버 배포를 붙일 때 |

앱을 만드는 문서는 각 모듈에 있다 — [backend/README.md](../backend/README.md),
[frontend/README.md](../frontend/README.md). CI 파일 지도는 [.github/README.md](../.github/README.md).
