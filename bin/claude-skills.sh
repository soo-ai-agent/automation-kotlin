#!/usr/bin/env bash
# 이 저장소의 코딩 규칙 스킬을 얹은 Claude 세션을 연다.
#
# 어디서 실행해도 된다 — 스크립트 자기 위치로 저장소를 찾으므로 절대 경로로 부르면 그만이다.
#
#   /경로/automation-kotlin/bin/claude-skills.sh install     # 짧은 명령어 3개를 깐다 (한 번만)
#   claude-be / claude-fe / claude-all                       # 깐 뒤에는 이렇게만 친다
#
# 뒤에 붙인 인자는 claude 로 그대로 넘어간다 — `claude-be -c` 는 백엔드 자리에서 이어서 대화하기다.
set -euo pipefail

# readlink -f 로 심볼릭 링크를 풀어, 링크로 불러도 저장소 원본 위치를 찾는다
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
REPO_ROOT="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"

# 깔리는 명령어 이름 = 영역. 링크 이름으로 불리면 인자 없이 그 영역이 열린다
declare -A LINKS=([claude-be]=backend [claude-fe]=frontend [claude-all]=all)
BIN_DIR="${CLAUDE_SKILLS_BIN_DIR:-$HOME/.local/bin}"

usage() {
    cat << USAGE
사용법
  claude-be                     백엔드 자리에서 열기 — kotlin-* 스킬
  claude-fe                     프론트 자리에서 열기 — frontend-* 스킬
  claude-all                    저장소 전체에서 열기 — 모든 스킬

  $(basename "$SCRIPT_PATH") install     위 세 명령어를 $BIN_DIR 에 깐다 (한 번만)
  $(basename "$SCRIPT_PATH") [backend|frontend|all] [claude 옵션...]

어느 자리에서 열든 루트 CLAUDE.md 와 공통 스킬(.claude/skills/)은 항상 함께 적용된다.
뒤에 붙인 인자는 claude 로 그대로 넘어간다 (예: claude-be -c 는 이어서 대화).
저장소: $REPO_ROOT
USAGE
}

install_links() {
    mkdir -p "$BIN_DIR"
    for name in "${!LINKS[@]}"; do
        ln -sf "$SCRIPT_PATH" "$BIN_DIR/$name"
        echo "  $BIN_DIR/$name  →  ${LINKS[$name]}"
    done
    echo
    case ":$PATH:" in
        *":$BIN_DIR:"*)
            echo "완료. 이제 어디서든 claude-be · claude-fe · claude-all 로 열면 된다."
            ;;
        *)
            echo "완료. 다만 $BIN_DIR 이 PATH 에 없어서 아직 이름만으로는 안 불린다."
            echo "셸 설정(~/.bashrc 또는 ~/.zshrc)에 아래 한 줄을 넣고 터미널을 다시 연다."
            echo
            echo "  export PATH=\"\$PATH:$BIN_DIR\""
            ;;
    esac
}

# 링크 이름으로 불렸으면 그 이름이 영역이다 — 인자를 먹지 않고 전부 claude 로 넘긴다
AREA="${LINKS[$(basename "$0")]:-}"
if [ -z "$AREA" ]; then
    AREA="${1:-all}"
    [ $# -gt 0 ] && shift
fi

case "$AREA" in
    backend | be)
        TARGET="$REPO_ROOT/backend"
        LABEL="백엔드 — kotlin-* + 공통 스킬"
        ;;
    frontend | fe)
        TARGET="$REPO_ROOT/frontend"
        LABEL="프론트엔드 — frontend-* + 공통 스킬"
        ;;
    all | root)
        TARGET="$REPO_ROOT"
        LABEL="저장소 전체 — 모든 스킬"
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

[ -d "$TARGET" ] || {
    echo "폴더가 없어요: $TARGET" >&2
    exit 1
}

echo "▶ $LABEL"
echo "  자리: $TARGET"

cd "$TARGET"

# 루트에서 열 때는 --add-dir 이 필요 없다. 하위에서 열 때만 저장소 전체를 읽을 수 있게 더한다
# — CONTRACT.md·common/docs 처럼 경계 밖 문서를 스킬이 참조하기 때문이다.
if [ "$TARGET" = "$REPO_ROOT" ]; then
    exec claude "$@"
fi
exec claude --add-dir "$REPO_ROOT" "$@"
