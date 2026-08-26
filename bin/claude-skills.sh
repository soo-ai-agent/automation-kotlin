#!/usr/bin/env bash
# 이 저장소의 코딩 규칙 스킬을 얹은 Claude 세션을 연다.
#
# 어디서 실행해도 된다 — 스크립트 자기 위치로 저장소를 찾으므로 절대 경로로 부르면 그만이다.
#
#   /경로/automation-kotlin/bin/claude-skills.sh backend
#   /경로/automation-kotlin/bin/claude-skills.sh frontend
#   /경로/automation-kotlin/bin/claude-skills.sh            # 저장소 전체
#
# 뒤에 붙인 인자는 claude 로 그대로 넘어간다 — `... backend -c` 는 백엔드 자리에서 이어서 대화하기다.
set -euo pipefail

# readlink -f 로 심볼릭 링크를 풀어, PATH 에 링크를 걸어 두어도 저장소를 제대로 찾는다
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
REPO_ROOT="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"

usage() {
    cat << USAGE
사용법: $(basename "$SCRIPT_PATH") [backend|frontend|all] [claude 옵션...]

  backend   backend/ 에서 연다 — 백엔드 스킬(kotlin-*)이 주로 적용된다
  frontend  frontend/ 에서 연다 — 프론트 스킬(frontend-*)이 주로 적용된다
  all       저장소 루트에서 연다 (기본값) — 양쪽을 다 만질 때

어느 자리에서 열든 루트 CLAUDE.md 와 공통 스킬(.claude/skills/)은 항상 함께 적용된다.
저장소: $REPO_ROOT
USAGE
}

AREA="${1:-all}"
[ $# -gt 0 ] && shift

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
