# 내 컴퓨터에서 같은 규칙으로 Claude 쓰기

> **이 문서는 사람이 읽습니다.**

GitHub 에이전트는 이 저장소의 코딩 규칙(스킬)을 읽고 일한다. **내 컴퓨터에서 Claude 를 직접 열 때도 같은 규칙을 그대로 쓸 수 있다.**

터미널에서 `claude` 를 그냥 치면 규칙 없이 열린다. 아래 launcher 로 열면 3대 원칙·리뷰 규칙·영역별 스킬이 함께 붙는다.

[처음 켜기(setup.md)](setup.md) 와는 별개다 — GitHub 자동화를 안 쓰더라도 이것만 깔아 쓸 수 있다.

## 한 번만 — 명령어 깔기

저장소의 launcher 를 `install` 로 한 번 실행하면 짧은 명령어 세 개가 깔린다. 저장소를 내려받은 경로가 `~/work/automation-kotlin` 이라면:

```bash
~/work/automation-kotlin/bin/claude-skills.sh install
```

`~/.local/bin/` 에 `claude-be`·`claude-fe`·`claude-all` 이 만들어진다. 그 폴더가 PATH 에 없으면 넣을 한 줄을 알려 주므로,
그것만 셸 설정(`~/.bashrc` 또는 `~/.zshrc`)에 붙이고 터미널을 다시 연다.

준비물은 claude CLI 하나다. 없으면 launcher 가 설치 명령을 알려 준다.

```bash
npm install -g @anthropic-ai/claude-code
claude setup-token
```

## 그다음부터 — 이렇게만 친다

```bash
claude-be      # 백엔드 자리에서 열기
claude-fe      # 프론트 자리에서 열기
claude-all     # 저장소 전체
```

어느 폴더에서 쳐도 된다. 셋 다 **저장소 루트에서** 열린다 — 루트 `CLAUDE.md` 와 거기 딸린 3대 원칙·리뷰 규칙(MUST)이
통째로 읽히는 자리가 루트뿐이기 때문이다. 하위 폴더에서 열면 그 규칙들이 조용히 빠진다.

다른 것은 **작업 영역**이다. `claude-be` 는 "backend/ 안에서만 고치고 kotlin-* 을 따른다"를,
`claude-fe` 는 그 반대를 세션 시작부터 지시해 둔다. 반대편은 계약 확인용으로 읽기만 한다.

뒤에 붙인 것은 claude 로 그대로 넘어간다. `claude-be -c` 는 백엔드 자리에서 이전 대화를 이어서 여는 것이다.

깔지 않고 쓸 수도 있다 — `bin/claude-skills.sh backend` 처럼 절대 경로로 부르면 같은 동작이다.


## 맥에서 (macOS)

리눅스와 명령은 같고, 셸과 PATH 관례만 다르다. 순서대로 하면 된다.

① **claude CLI 준비.** Node 가 없으면 [Homebrew](https://brew.sh) 로 먼저 깐다.

```bash
brew install node                             # 이미 있으면 건너뛴다
npm install -g @anthropic-ai/claude-code
claude setup-token                            # 브라우저가 열리며 로그인한다
```

`npm install -g` 에서 권한 오류(`EACCES`)가 나면 `sudo` 를 붙이지 말고 Homebrew 로 깐 Node 를 쓰는 편이 안전하다.
`which node` 가 `/opt/homebrew/bin/node`(애플 실리콘) 또는 `/usr/local/bin/node`(인텔) 를 가리키면 정상이다.

② **launcher 깔기.** 저장소를 내려받은 경로에서 한 번만 실행한다.

```bash
~/work/automation-kotlin/bin/claude-skills.sh install
```

③ **PATH 에 넣기.** 맥의 기본 셸은 **zsh** 이므로 `~/.zshrc` 다(`~/.bashrc` 가 아니다).

```bash
echo 'export PATH="$PATH:$HOME/.local/bin"' >> ~/.zshrc
source ~/.zshrc
```

`~/.local/bin` 이 없어도 `install` 이 만들어 두므로 그대로 넣으면 된다.
셸이 zsh 인지 확인하려면 `echo $SHELL` 이 `/bin/zsh` 인지 본다 — `bash` 로 나오면 `~/.bash_profile` 에 같은 줄을 넣는다.

④ **확인.**

```bash
claude-be --help
```

사용법이 나오면 끝이다.

**맥의 기본 bash 는 3.2 지만 launcher 는 그대로 돈다** — 연관배열과 `readlink -f` 처럼 그 버전에 없는 것을 쓰지 않도록 만들었다.

## 무엇이 자동으로 붙나

| 붙는 것 | 언제 |
|---|---|
| 루트 `CLAUDE.md` 본문 | 명령 즉시 |
| 3대 원칙(`core-principles`) 전문 | 명령 즉시 — `CLAUDE.md` 의 import |
| 리뷰 규칙 `rules.md`(MUST/SHOULD) 전문 | 명령 즉시 — 같은 import |
| 작업 영역 지시 (backend/ 만 고친다 등) | 명령 즉시 — `claude-be`·`claude-fe` 만 |
| 스킬 34종의 이름·설명 | 명령 즉시 |
| 개별 스킬 **본문** | 그 작업이 시작될 때 |

마지막 줄만 즉시가 아니다. 스킬이 34종이라 본문을 전부 미리 읽으면 대화할 자리가 남지 않기 때문이고,
대신 목록과 설명이 항상 떠 있어서 필요한 순간에 해당 스킬이 열린다.

## 안 될 때

**`claude-be: command not found`** — `~/.local/bin` 이 PATH 에 없다. `install` 이 알려 준 `export PATH=...` 한 줄을
셸 설정에 넣고 터미널을 다시 연다 — **맥은 `~/.zshrc`, 리눅스는 보통 `~/.bashrc`** 다.
확인은 `echo $PATH | tr ':' '\n' | grep local/bin` 이다.

**`claude CLI 가 없어요`** — `npm install -g @anthropic-ai/claude-code` 로 깔고 `claude setup-token` 으로 로그인한다.

**저장소를 다른 곳으로 옮겼다** — 링크가 옛 경로를 가리킨다. 옮긴 자리에서 `bin/claude-skills.sh install` 을 다시 돌리면 덮어쓴다.

**규칙이 안 붙는 것 같다** — 세션에서 이렇게 물어본다.

```
도구 쓰지 말고 답해: 지금 적용되는 3대 원칙의 이름 3개와, 이번 세션의 작업 영역은?
```

3대 원칙 이름(단순함 최우선 · 최소 수정·무파괴 · 데이터의 흐름과 통제)과 영역이 나오면 정상이다.

---

launcher 자체를 고치려면 [bin/claude-skills.sh](../bin/claude-skills.sh) 를 연다. 규칙 문서를 고치는 자리는 [setup.md](setup.md#켠-다음--어디서-무엇을-바꾸나) 에 있다.
