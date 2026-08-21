#!/usr/bin/env bash
# 한국어 프리셋 원본이 바뀌었는데 설치본이 그대로일 때 알린다 — PostToolUse(Write|Edit) 훅.
#
# 왜 필요한가: `specify preset add --dev` 는 심볼릭 링크가 아니라 **복사**다.
# 그래서 common/speckit-ko/ 를 고치고 설치 스크립트를 다시 돌리지 않으면,
# /speckit-* 가 계속 예전 번역을 쓴다. 조용히 어긋나므로 알아채기 어렵다.
#
# 한계: 에이전트가 고칠 때만 걸린다. 사람이 편집기로 직접 고치면 이 훅은 모른다.
set -u

payload="$(cat)"

# 고친 파일 경로를 뽑는다. jq 가 없을 수도 있어 sed 로 대비한다.
if command -v jq >/dev/null 2>&1; then
    path=$(printf '%s' "$payload" | jq -r '.tool_input.file_path // .tool_response.filePath // empty' 2>/dev/null)
else
    path=$(printf '%s' "$payload" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
fi

case "$path" in
    *common/speckit-ko/*) ;;
    *) exit 0 ;;
esac

root="${CLAUDE_PROJECT_DIR:-.}"
src="$root/common/speckit-ko"
installed="$root/.specify/presets/korean"

# 아직 설치한 적이 없으면 어긋날 것도 없다.
[ -d "$installed" ] || exit 0

if ! diff -rq "$src" "$installed" >/dev/null 2>&1; then
    cat <<'JSON'
{"systemMessage":"한국어 프리셋 원본이 설치본과 어긋났습니다. 등록은 복사라서, 다시 깔기 전까지 /speckit-* 는 예전 번역을 씁니다.\n  bash .github/agent/setup-speckit.sh"}
JSON
fi

exit 0
