# 내 컴퓨터에서 같은 규칙으로 Claude 쓰기

> **이 문서는 사람이 읽습니다.**

GitHub 에이전트는 이 저장소의 코딩 규칙(스킬)을 읽고 일한다. **내 컴퓨터에서 Claude 를 직접 열 때도 같은 규칙을 그대로 쓸 수 있다.**

터미널에서 `claude` 를 그냥 치면 규칙 없이 열린다. 이 저장소의 **launcher**(claude 를 대신 실행해 주는 작은 스크립트)로 열면
3대 원칙·리뷰 규칙·영역별 스킬이 함께 붙는다.

launcher 는 둘이고, 무엇을 붙이느냐가 다르다.

| launcher | 명령어 | 어디서 열리나 | 스킬 |
|---|---|---|---|
| `bin/claude-skills.sh` | `claude-be` · `claude-fe` · `claude-all` | 늘 저장소 루트 | 이름·설명만 — 본문은 그 작업이 시작될 때 |
| `bin/ccsk` | `ccsk be` · `ccsk fe` · `ccsk` | 지금 서 있는 폴더 | **전문을 미리 싣는다** |

이 저장소 안에서 일하면 `claude-be` 로 충분하다. `ccsk` 는 스킬 본문을 세션 시작부터 통째로 올려 두고 싶을 때,
그리고 **다른 폴더에서 이 저장소의 규칙만 빌려 쓸 때** 쓴다. 자세한 것은 [아래 절](#스킬-본문까지-미리-싣기--ccsk)에 있다.

[처음 켜기(setup.md)](setup.md) 와는 별개다 — GitHub 자동화를 안 쓰더라도 이것만 깔아 쓸 수 있다.

## 한 번만 — 명령어 깔기

리눅스 기준이다. 맥은 [아래 맥 절](#맥에서-macos)에 순서가 따로 있다.

**1. claude CLI 를 깐다.** CLI 는 터미널에서 Claude 를 쓰는 프로그램이다. 이미 있으면 건너뛴다.

```bash
npm install -g @anthropic-ai/claude-code   # claude 명령을 컴퓨터에 설치
claude setup-token                          # 브라우저가 열리며 로그인한다
```

**2. launcher 를 `install` 로 한 번 실행한다.** 저장소를 내려받은 경로가 `~/work/automation-kotlin` 이라면:

```bash
~/work/automation-kotlin/bin/claude-skills.sh install
```

`~/.local/bin/` 에 `claude-be`·`claude-fe`·`claude-all` 세 개가 만들어진다.

**3. PATH 에 그 폴더를 넣는다.** PATH 는 터미널이 명령어 파일을 찾아다니는 폴더 목록이다. 여기 없으면 이름만 쳐서는 실행되지 않는다.

`install` 이 넣을 한 줄을 알려 주므로, 그것만 셸 설정 파일(`~/.bashrc`)에 붙이고 터미널을 다시 연다.

## 그다음부터 — 이렇게만 친다

```bash
claude-be      # 백엔드 작업으로 열기
claude-fe      # 프론트 작업으로 열기
claude-all     # 저장소 전체
```

어느 폴더에서 쳐도 된다. 셋 다 **저장소 루트에서** 열린다 — 루트 `CLAUDE.md` 와 거기 딸린 3대 원칙·리뷰 규칙(MUST)이
통째로 읽히는 자리가 루트뿐이기 때문이다. 하위 폴더에서 열면 그 규칙들이 빠진 채로 열린다.

> **확정** — `backend/` 에서 열어 리뷰 규칙 본문을 물었을 때 "모름", 루트에서는 정확히 답하는 것을 확인 (2026-08-26).

셋의 차이는 **작업 영역**이다. `claude-be` 는 "backend/ 안에서만 고치고 kotlin-* 스킬을 따른다"를,
`claude-fe` 는 그 반대를 세션 시작부터 지시해 둔다. 반대편은 계약 확인용으로 읽기만 한다.

뒤에 붙인 것은 claude 로 그대로 넘어간다. `claude-be -c` 는 백엔드 작업으로 이전 대화를 이어서 여는 것이다.

깔지 않고 쓸 수도 있다 — `bin/claude-skills.sh backend` 처럼 절대 경로로 부르면 같은 동작이다.

## 스킬 본문까지 미리 싣기 — `ccsk`

`claude-be` 는 스킬의 **이름과 설명**만 올려 두고, 본문은 그 작업이 시작될 때 열린다. 필요한 것만 읽으니 가볍지만,
에이전트가 스킬을 안 열고 지나가면 규칙이 빠진 채로 코드가 나온다.

`ccsk` 는 그 자리를 메운다 — 해당 영역 스킬의 `SKILL.md` **전문**을 한 파일로 모아 세션 시작부터 붙인다.

```bash
ln -sf ~/work/automation-kotlin/bin/ccsk ~/.local/bin/ccsk   # 한 번만
```

```bash
ccsk be        # 공통 3종 + kotlin-* 17종 전문 (약 180KB)
ccsk fe        # 공통 3종 + frontend-* 7종 전문 (약 130KB)
ccsk           # 둘 다 (약 260KB)
```

싣는 공통 스킬은 늘 적용되는 셋(`core-principles` · `ponytail` · `oop-responsibility-design`)뿐이다.
`ponytail-review` 처럼 불러야 도는 스킬과, 분량이 큰 벤더링 `expo/` 문서는 넣지 않는다 — 필요할 때 그 자리에서 열린다.

**`claude-be` 와 다른 점이 하나 더 있다. `ccsk` 는 저장소 루트로 옮겨가지 않고 지금 서 있는 폴더에서 연다.**
규칙은 이 저장소에서 가져오고 작업 대상은 지금 폴더라, 이 저장소 밖의 프로젝트에서도 같은 규칙으로 열 수 있다.

대신 다른 폴더에서 열면 루트 `CLAUDE.md` 와 그 import 인 리뷰 규칙(`rules.md`)은 붙지 않는다. 3대 원칙은 번들에 들어 있어 그대로 붙는다.
리뷰 규칙 MUST 까지 필요하면 저장소 루트에서 `ccsk be` 를 치거나 `claude-be` 를 쓴다.

> **확정** — 저장소 밖(`/tmp`)에서 `ccsk be` 로 열어, 도구를 쓰지 않고 3대 원칙 이름 3개와
> `kotlin-entity` 의 `protected set` + 행위 메서드 규칙을 답하는 것을 확인 (2026-09-01).

## 맥에서 (macOS)

리눅스와 명령은 같고, 셸과 PATH 관례만 다르다. 순서대로 하면 된다.

① **저장소 내려받기.** 이미 받아 뒀으면 건너뛴다. 경로는 어디든 되고, 아래는 `~/work` 아래에 두는 예다.

```bash
mkdir -p ~/work && cd ~/work                          # 저장소를 둘 폴더를 만들고 그리로 이동
git clone <이 저장소 주소> automation-kotlin           # automation-kotlin 이라는 이름으로 내려받는다
```

② **claude CLI 준비.** Node 가 없으면 [Homebrew](https://brew.sh)(맥에서 개발 도구를 설치하는 프로그램)로 먼저 깐다.

```bash
brew install node                             # 이미 있으면 건너뛴다
npm install -g @anthropic-ai/claude-code      # claude 명령 설치
claude setup-token                            # 브라우저가 열리며 로그인한다
```

`npm install -g` 에서 권한 오류(`EACCES` — 그 폴더에 쓸 권한이 없다는 뜻)가 나면 `sudo` 를 붙이지 말고 Homebrew 로 깐 Node 를 쓰는 편이 안전하다.

`which node` 를 쳐서 `/opt/homebrew/bin/node`(애플 실리콘) 또는 `/usr/local/bin/node`(인텔) 가 나오면 Homebrew Node 를 쓰고 있는 것이다.

③ **launcher 깔기.** 내려받은 경로에서 한 번만 실행한다.

```bash
~/work/automation-kotlin/bin/claude-skills.sh install
```

④ **PATH 에 넣기.** 맥의 기본 셸(명령을 받아 실행하는 프로그램)은 **zsh** 이므로 설정 파일이 `~/.zshrc` 다. `~/.bashrc` 가 아니다.

```bash
echo 'export PATH="$PATH:$HOME/.local/bin"' >> ~/.zshrc   # 설정 파일 끝에 한 줄 덧붙인다
source ~/.zshrc                                            # 지금 터미널에 즉시 반영한다
```

`~/.local/bin` 이 아직 없어도 `install` 이 만들어 두므로 그대로 넣으면 된다.

셸이 zsh 인지 확인하려면 `echo $SHELL` 을 친다. `/bin/zsh` 가 나오면 위 그대로 하면 되고, `bash` 가 나오면 `~/.bash_profile` 에 같은 줄을 넣는다.

⑤ **확인.**

```bash
claude-be --help          # 사용법이 나오면 명령어는 제대로 깔린 것이다
claude-be                 # 실제로 열어 본다
```

열린 세션에서 아래를 그대로 물어 규칙이 붙었는지 눈으로 확인한다.

```
도구 쓰지 말고 답해: 지금 적용되는 3대 원칙의 이름 3개와, 이번 세션의 작업 영역은?
```

3대 원칙 이름(단순함 최우선 · 최소 수정·무파괴 · 데이터의 흐름과 통제)과 `backend/` 가 나오면 정상이다.

**맥의 기본 bash 는 3.2 지만 launcher 는 그대로 돈다.** 그 버전에 없는 문법(연관배열 `declare -A`, `readlink -f` 옵션)을 쓰지 않도록 만들었다.

> **추정** — 리눅스에서 설치·실행·링크 해결을 확인했고(2026-08-26), 3.2 에서만 깨지는 문법이 남지 않았음을 검사했다.
> 맥 실기에서 돌려본 것은 아니다. ⑤에서 막히면 그 출력을 알려 주면 된다.

## 무엇이 자동으로 붙나

| 붙는 것 | 언제 |
|---|---|
| 루트 `CLAUDE.md` 본문 | 명령 즉시 |
| 3대 원칙(`core-principles`) 전문 | 명령 즉시 — `CLAUDE.md` 가 import 로 끌어온다 |
| 리뷰 규칙 `rules.md`(MUST/SHOULD) 전문 | 명령 즉시 — 같은 import |
| 작업 영역 지시 (backend/ 만 고친다 등) | 명령 즉시 — `claude-be`·`claude-fe` 만 |
| 스킬 이름·설명 — 공통 9종 + 그 영역(백엔드 17 · 프론트 7) | 명령 즉시 — launcher 가 그 영역을 `--add-dir` 로 열어 준다 |
| 개별 스킬 **본문** | 그 작업이 시작될 때 — `ccsk` 로 열면 해당 영역은 명령 즉시 |
| 벤더링된 expo 18종 | **붙지 않는다** — 한 단계 깊어서 목록에 없다. 프론트 스킬이 가리키는 자리에서 파일로 읽는다 |

여기서 import 는 `CLAUDE.md` 안의 `@경로` 한 줄로, 그 파일 내용을 통째로 끌어와 함께 읽게 하는 표시다.

```markdown
# CLAUDE.md 끝부분 — 이 두 줄이 원칙과 리뷰 규칙 전문을 끌어온다
@.claude/skills/core-principles/SKILL.md

@common/docs/code-review/rules.md
```

마지막 줄만 즉시가 아니다. 스킬이 33종이라 본문을 전부 미리 읽으면 한 번에 다룰 수 있는 분량을 넘긴다.

하위 폴더(`backend/`·`frontend/`)의 스킬은 `--add-dir` 로 열어 줘야 목록에 뜬다. 저장소 루트에서 그냥 `claude` 를 치면 공통 9종만 보인다.
대신 목록과 설명이 항상 떠 있어서, 필요한 순간에 해당 스킬 본문이 열린다.

> **확정** — `claude-be` 로 리뷰 규칙 본문(하이픈 규칙과 `/api/v1/order-items` 예시)을 도구 없이 답하는 것과,
> 작업 영역을 `backend/` 로 인식하는 것을 확인 (2026-08-26).

## 안 될 때

**`claude-be: command not found`** — `~/.local/bin` 이 PATH 에 없다. `install` 이 알려 준 `export PATH=...` 한 줄을
셸 설정에 넣고 터미널을 다시 연다 — **맥은 `~/.zshrc`, 리눅스는 보통 `~/.bashrc`** 다.

확인은 아래 명령이다. `local/bin` 이 한 줄 나오면 들어간 것이고, 아무것도 안 나오면 아직 안 들어갔다.

```bash
echo $PATH | tr ':' '\n' | grep local/bin
```

**`claude CLI 가 없어요`** — `npm install -g @anthropic-ai/claude-code` 로 깔고 `claude setup-token` 으로 로그인한다.

**저장소를 다른 곳으로 옮겼다** — 링크가 옛 경로를 가리킨다. 옮긴 자리에서 `bin/claude-skills.sh install` 을 다시 돌리면 덮어쓴다.

**규칙이 안 붙는 것 같다** — 맥 절차 ⑤의 확인 질문을 그대로 세션에 물어본다. 3대 원칙 이름과 작업 영역이 나오면 정상이다.

---

launcher 자체를 고치려면 [bin/claude-skills.sh](../bin/claude-skills.sh) 나 [bin/ccsk](../bin/ccsk) 를 연다.

규칙 문서를 고치는 자리는 [setup.md](setup.md#켠-다음--어디서-무엇을-바꾸나) 에 있다.
