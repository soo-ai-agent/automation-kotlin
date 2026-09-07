# 내 컴퓨터에서 같은 규칙으로 Claude 쓰기

> **이 문서는 사람이 읽습니다.**

GitHub 에이전트는 이 저장소의 코딩 규칙(스킬)을 읽고 일한다. **내 컴퓨터에서 Claude 를 직접 열 때도 같은 규칙을 그대로 쓸 수 있다.**

터미널에서 `claude` 를 그냥 치면 규칙 없이 열린다. 이 저장소의 **launcher**(claude 를 대신 실행해 주는 작은 스크립트, `bin/claude-skills.sh`)로 열면
3대 원칙·리뷰 규칙·영역별 스킬이 함께 붙는다.

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

셋의 차이는 **작업 영역과 붙는 스킬**이다. `claude-be` 는 "backend/ 안에서만 고치고 kotlin-* 스킬을 따른다"를,
`claude-fe` 는 그 반대를 세션 시작부터 지시해 둔다. 반대편은 계약 확인용으로 읽기만 한다.

| 명령 | 붙는 스킬 | 개수 |
|---|---|---|
| `claude-be` | 공통 + `kotlin-*` | 9 + 17 |
| `claude-fe` | 공통 + `frontend-*` | 9 + 8 |
| `claude-all` | 공통 + `kotlin-*` + `frontend-*` | 34 전부 |

**그냥 `claude` 로 열면 세션이 시작될 때 공통 9종만 붙는다.** claude 는 연 자리의 `.claude/skills/` 부터 뒤지므로
루트에서 열면 `backend/`·`frontend/` 아래 스킬 25종은 목록에 없다. 그 폴더의 파일을 한 번 읽고 나면 뒤늦게 붙지만,
그때는 **이미 규칙 없이 첫 판단을 내린 뒤**다. launcher 는 `--add-dir` 로 그 폴더를 처음부터 붙여 이 구멍을 막는다.

> **확정** — 루트에서 그냥 열어 물었을 때 `kotlin-*`·`frontend-*` 가 목록에 하나도 없고, `--add-dir backend --add-dir frontend` 를 붙이면
> 25종이 전부 목록에 뜨는 것을 확인 (2026-09-07, CLI 2.1.220).
>
> `settings.json` 의 `permissions.additionalDirectories` 로는 안 붙는다 — 같은 폴더를 넣어도 목록은 그대로였다. `--add-dir` 플래그여야 한다.

뒤에 붙인 것은 claude 로 그대로 넘어간다. `claude-be -c` 는 백엔드 작업으로 이전 대화를 이어서 여는 것이다.

깔지 않고 쓸 수도 있다 — `bin/claude-skills.sh backend` 처럼 절대 경로로 부르면 같은 동작이다.

## 셋 다 권한 확인 창 없이 열린다

launcher 는 `--dangerously-skip-permissions` 를 붙여 연다. 파일을 고치거나 명령을 돌릴 때마다 뜨던 **"허용하시겠습니까"가 안 뜬다.**

편한 대신 안전장치가 하나 빠진 것이다. 지켜야 할 것은 셋이다.

- **세션이 하는 일을 보고 있는다.** 무엇을 고치는지 눈으로 따라가는 것이 유일하게 남은 제동 장치다.

- **작업 전에 커밋해 둔다.** 되돌릴 지점이 있어야 잘못 고쳤을 때 `git checkout` 한 번으로 끝난다.

- **이 저장소에서만 쓴다.** launcher 는 언제나 이 저장소 루트에서 열리므로 남의 코드에 닿지 않지만, 같은 옵션을 다른 곳에서 습관처럼 쓰지 않는다.

원래대로 확인 창을 받고 싶으면 launcher 대신 `claude` 를 직접 연다 — 대신 영역 스킬은 붙지 않는다.

## 하네스도 영역별로 돈다

규칙 문서(스킬·리뷰 규칙)를 고쳤으면 리뷰어 판정이 흔들리지 않았는지 하네스로 확인한다. 검사는 둘이고, **싼 것부터** 돌린다.

```bash
bash common/harness-tests/static.sh         # ① 형식 검사 — 공짜, 1초
bash common/harness-tests/run.sh backend    # ② 판정 회귀 — 백엔드 케이스만 (5건)
bash common/harness-tests/run.sh frontend   #    프론트 케이스만 (2건)
bash common/harness-tests/run.sh            #    전부
```

**①은 모델을 부르지 않는다.** 스킬 색인의 링크가 죽지 않았는지, 하네스가 돌아야 할 경로가 워크플로 필터에 다 들어 있는지 같은 것을 본다. 규칙이 옳은지가 아니라 **규칙이 읽히기는 하는지**를 검사한다.

**②는 케이스 하나가 claude 호출 1건**이다. 백엔드 스킬만 고쳤으면 `backend` 만 돌리면 된다. 영역은 어느 케이스를 돌릴지만 고르고, 리뷰어는 언제나 실제 PR 리뷰어와 똑같은 방식으로 불린다.

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
| 스킬의 이름·설명 (영역에 따라 26·17·34종) | 명령 즉시 — launcher 가 `--add-dir` 로 하위 스킬 폴더를 붙인다 |
| 개별 스킬 **본문** | 그 작업이 시작될 때 |

여기서 import 는 `CLAUDE.md` 안의 `@경로` 한 줄로, 그 파일 내용을 통째로 끌어와 함께 읽게 하는 표시다.

```markdown
# CLAUDE.md 끝부분 — 이 두 줄이 원칙과 리뷰 규칙 전문을 끌어온다
@.claude/skills/core-principles/SKILL.md

@common/docs/code-review/rules.md
```

마지막 줄만 즉시가 아니다. 스킬이 34종이라 본문을 전부 미리 읽으면 한 번에 다룰 수 있는 분량을 넘긴다.
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

launcher 자체를 고치려면 [bin/claude-skills.sh](../bin/claude-skills.sh) 를 연다. 규칙 문서를 고치는 자리는 [setup.md](setup.md#켠-다음--어디서-무엇을-바꾸나) 에 있다.
