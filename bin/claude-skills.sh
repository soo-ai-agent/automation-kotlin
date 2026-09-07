#!/usr/bin/env bash
# 이 저장소의 코딩 규칙 스킬을 얹은 Claude 세션을 연다.
#
# 어디서 실행해도 된다 — 스크립트 자기 위치로 저장소를 찾으므로 절대 경로로 부르면 그만이다.
#
#   /경로/automation-kotlin/bin/claude-skills.sh install     # 짧은 명령어 3개를 깐다 (한 번만)
#   claude-be / claude-fe / claude-all                       # 깐 뒤에는 이렇게만 친다
#
# 뒤에 붙인 인자는 claude 로 그대로 넘어간다 — `claude-be -c` 는 백엔드 자리에서 이어서 대화하기다.
#
# 셋 다 권한 확인 창 없이 연다 (--dangerously-skip-permissions).
set -euo pipefail

# 심볼릭 링크를 풀어 저장소 원본 위치를 찾는다.
# readlink -f 를 쓰지 않는 이유는 macOS(BSD) 에 그 옵션이 없기 때문이다 — 직접 따라간다.
resolve_link() {
    path="$1"
    while [ -L "$path" ]; do
        target="$(readlink "$path")"
        case "$target" in
            /*) path="$target" ;;
            *) path="$(dirname "$path")/$target" ;;
        esac
    done
    printf '%s/%s' "$(cd "$(dirname "$path")" && pwd)" "$(basename "$path")"
}

SCRIPT_PATH="$(resolve_link "${BASH_SOURCE[0]}")"
REPO_ROOT="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"

# 깔리는 명령어 이름 = 영역. 링크 이름으로 불리면 인자 없이 그 영역이 열린다.
# 연관배열(declare -A)을 쓰지 않는 이유는 macOS 기본 bash 가 3.2 라 지원하지 않기 때문이다.
LINK_NAMES="claude-be claude-fe claude-all"
area_of_link() {
    case "$1" in
        claude-be) echo backend ;;
        claude-fe) echo frontend ;;
        claude-all) echo all ;;
        *) echo "" ;;
    esac
}
BIN_DIR="${CLAUDE_SKILLS_BIN_DIR:-$HOME/.local/bin}"

usage() {
    cat << USAGE
사용법
  claude-be                     백엔드 작업 — 공통 + kotlin-* 스킬, 변경은 backend/ 안에서만
  claude-fe                     프론트 작업 — 공통 + frontend-* 스킬, 변경은 frontend/ 안에서만
  claude-all                    저장소 전체 — 공통 + kotlin-* + frontend-* 전부

  $(basename "$SCRIPT_PATH") install     위 세 명령어를 $BIN_DIR 에 깐다 (한 번만)
  $(basename "$SCRIPT_PATH") [backend|frontend|all] [claude 옵션...]

셋 다 저장소 루트에서 열린다 — 루트 CLAUDE.md 와 그 import(3대 원칙·리뷰 규칙)가 통째로 읽히는 자리다.
셋 다 권한 확인 창 없이 연다(--dangerously-skip-permissions) — 세션이 하는 일을 사람이 보고 있어야 한다.
뒤에 붙인 인자는 claude 로 그대로 넘어간다 (예: claude-be -c 는 이어서 대화).
저장소: $REPO_ROOT

하네스: bash common/harness-tests/run.sh [backend|frontend|all]
USAGE
}

install_links() {
    mkdir -p "$BIN_DIR"
    for name in $LINK_NAMES; do
        ln -sf "$SCRIPT_PATH" "$BIN_DIR/$name"
        echo "  $BIN_DIR/$name  →  $(area_of_link "$name")"
    done
    echo
    case ":$PATH:" in
        *":$BIN_DIR:"*)
            echo "완료. 이제 어디서든 claude-be · claude-fe · claude-all 로 열면 된다."
            ;;
        *)
            echo "완료. 다만 $BIN_DIR 이 PATH 에 없어서 아직 이름만으로는 안 불린다."
            echo "셸 설정에 아래 한 줄을 넣고 터미널을 다시 연다 — 맥 기본 셸은 zsh(~/.zshrc), 리눅스는 보통 bash(~/.bashrc) 다."
            echo
            echo "  export PATH=\"\$PATH:$BIN_DIR\""
            ;;
    esac
}

# 링크 이름으로 불렸으면 그 이름이 영역이다 — 인자를 먹지 않고 전부 claude 로 넘긴다
AREA="$(area_of_link "$(basename "$0")")"
if [ -z "$AREA" ]; then
    AREA="${1:-all}"
    [ $# -gt 0 ] && shift
fi

# 어느 자리를 고르든 claude 는 저장소 루트에서 연다.
# 하위 폴더에서 열면 루트 CLAUDE.md 의 @import(3대 원칙·리뷰 규칙 MUST)가 펼쳐지지 않아
# 최상위 규칙이 통째로 빠진다 — 실측으로 확인했다. 영역은 cwd 가 아니라 아래 FOCUS 로 좁힌다.
#
# 다만 루트에서 열면 claude 가 스킬을 루트 .claude/skills/ 에서만 찾는다.
# 하위 폴더의 스킬은 --add-dir 로 그 폴더를 붙여야 세션 스킬 목록에 오른다 — 안 붙이면
# kotlin-*·frontend-* 가 통째로 빠져서 이름조차 뜨지 않는다 (CLI 2.1.220 에서 실측).
# settings.json 의 permissions.additionalDirectories 로는 안 되고 --add-dir 플래그여야 한다.
FOCUS=""
ADD_DIRS=""
case "$AREA" in
    backend | be)
        LABEL="백엔드 — 공통 스킬 + kotlin-*"
        ADD_DIRS="--add-dir backend"
        FOCUS="이번 세션의 작업 영역은 backend/ 다. 코드 변경은 backend/ 안에서만 한다.
적용할 영역 스킬은 backend/.claude/skills/ 의 kotlin-* 이고, 색인은 backend/.claude/skills/README.md 다.
frontend/ 는 계약 확인(CONTRACT.md·응답 DTO 대조)을 위해 읽기만 하고 고치지 않는다."
        ;;
    frontend | fe)
        LABEL="프론트엔드 — 공통 스킬 + frontend-*"
        ADD_DIRS="--add-dir frontend"
        FOCUS="이번 세션의 작업 영역은 frontend/ 다. 코드 변경은 frontend/ 안에서만 한다.
적용할 영역 스킬은 frontend/.claude/skills/ 의 frontend-* 이고, 색인은 frontend/.claude/skills/README.md 다.
backend/ 는 계약 확인(CONTRACT.md·응답 DTO 대조)을 위해 읽기만 하고 고치지 않는다."
        ;;
    all | root)
        LABEL="저장소 전체 — 모든 스킬"
        ADD_DIRS="--add-dir backend --add-dir frontend"
        ;;
    install)
        install_links
        exit 0
        ;;
    -h | --help | help)
        usage
        exit 0
        ;;
    *)
        echo "모르는 자리: $AREA" >&2
        echo >&2
        usage >&2
        exit 2
        ;;
esac

command -v claude > /dev/null || {
    echo "claude CLI 가 없어요. 설치: npm install -g @anthropic-ai/claude-code" >&2
    echo "설치 후 로그인: claude setup-token" >&2
    exit 1
}

echo "▶ $LABEL"
echo "  저장소: $REPO_ROOT"

cd "$REPO_ROOT"

# 권한 확인 창을 띄우지 않는다 — 이 저장소 작업은 매번 승인을 누르는 값이 없다고 보고 끈 것이다.
# 대신 세션이 하는 일을 사람이 보고 있어야 한다. 낯선 저장소나 남의 코드에는 이 launcher 를 쓰지 않는다.
SKIP_PERMISSIONS="--dangerously-skip-permissions"

# ADD_DIRS 는 따옴표 없이 펼친다 — 폴더 이름에 공백이 없어 낱말 분리가 그대로 인자가 된다.
if [ -z "$FOCUS" ]; then
    exec claude $ADD_DIRS $SKIP_PERMISSIONS "$@"
fi
exec claude $ADD_DIRS $SKIP_PERMISSIONS --append-system-prompt "$FOCUS" "$@"
