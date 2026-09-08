# .claude — Claude Code 가 읽는 자리

> **이 폴더는 도구가 읽습니다.** 자리와 파일 형식은 Claude Code 가 정했고, 그 안에 담긴 내용은 따로 밝힌 것 말고는 전부 이 저장소가 쓴 것입니다.

폴더 이름과 하위 구조(`skills/`·`agents/`·`hooks/`·`workflows/`·`settings.json`)는 Claude Code 규약이다 — 우리가 고를 수 없다.

원본은 <https://docs.claude.com/claude-code> 이고, 담긴 내용의 출처는 아래와 같다.

| 파일·폴더 | 출처 | 커밋되나 |
|---|---|---|
| `skills/core-principles`·`api-contract`·`md-doc`·`oop-responsibility-design` | 이 저장소 자체 작성 | 예 |
| `skills/ponytail`·`ponytail-review` | DietrichGebert, MIT — <https://github.com/DietrichGebert/ponytail> | 예 (원본 그대로) |
| `skills/LICENSE` | 위 두 스킬의 MIT 라이선스 전문 | 예 |
| `skills/speckit-*` | GitHub, Inc., MIT — <https://github.com/github/spec-kit> | 아니오 — 설치물이라 `.gitignore` 가 거른다 |
| `hooks/*.sh` | 이 저장소 자체 작성 | 예 |
| `workflows/work.js` | 이 저장소 자체 작성 | 예 |
| `settings.json` | 이 저장소 자체 작성 (훅 두 개를 매다는 설정) | 예 |
| `agents/*.md` | 이 저장소 자체 작성 — `.github/agent/nodes/` 원본의 복사본 | 아니오 — 작업 브랜치가 자기 역할을 고치지 못하게 거른다 |

파일마다 첫 줄에도 같은 표시가 있다. `settings.json` 만 예외인데, JSON 은 주석을 담지 못해서 이 표가 그 자리를 대신한다.

빌려온 것의 원본 주소·라이선스·우리가 고친 부분은 [docs/upstream.md](../docs/upstream.md) 에 정리돼 있다.
