#!/usr/bin/env bash
# 스킬을 고치면 skill-creator 로 되돌아보게 한다 — PostToolUse(Write|Edit) 훅.
#
# 왜 필요한가: 스킬은 고쳐도 아무것도 실패하지 않는다. 컴파일도 테스트도 스킬 문서를 읽지 않아서,
# 이름이 폴더와 어긋나거나 description 이 트리거를 못 잡거나 링크가 깨져도 조용히 지나간다.
# CLAUDE.md 가 말하는 "규칙이 있으면 그것을 강제할 장치가 있는가"를 스킬 자신에게 적용한 것이다.
#
# 하는 일은 둘이다.
#   ① 기계가 셀 수 있는 불변식(이름·description·필수 절·링크)을 그 자리에서 검사한다.
#   ② 에이전트에게 skill-creator 호출을 지시한다 — 트리거 정확도처럼 세는 것으로 안 되는 것을 맡긴다.
#
# 한계 둘. Write·Edit 도구로 고칠 때만 걸린다 — Bash(sed) 로 고치거나 사람이 편집기로 고치면 지나간다.
# 그리고 세션·스킬당 한 번만 말한다 — 같은 파일을 연달아 고칠 때 같은 말을 반복하지 않기 위해서다.
set -u

payload="$(cat)"

read_field() {
    if command -v jq > /dev/null 2>&1; then
        printf '%s' "$payload" | jq -r "$1 // empty" 2> /dev/null
    else
        printf '%s' "$payload" | sed -n "s/.*\"$2\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -1
    fi
}

path="$(read_field '.tool_input.file_path // .tool_response.filePath' 'file_path')"

# 우리 규칙 스킬만 본다. 벤더링본(expo·speckit)은 상류 사본이라 고쳐 쓰는 대상이 아니다.
case "$path" in
    */.claude/skills/*/SKILL.md) ;;
    *) exit 0 ;;
esac
case "$path" in
    */skills/expo/* | */skills/speckit-*) exit 0 ;;
esac
[ -f "$path" ] || exit 0

dir="$(dirname "$path")"
skill="$(basename "$dir")"

# 세션·스킬당 한 번. session_id 를 못 읽으면 그냥 매번 말한다.
session="$(read_field '.session_id' 'session_id')"
# 파일 이름으로 쓰므로 경로 구분자가 섞이지 않게 걸러 낸다
session="$(printf '%s' "$session" | tr -cd 'A-Za-z0-9_-')"
if [ -n "$session" ]; then
    marker="${TMPDIR:-/tmp}/claude-skill-review-${session}-${skill}"
    [ -e "$marker" ] && exit 0
    : > "$marker"
fi

problems=""
add() { problems="${problems}\n  - $1"; }

# ① 이름이 폴더와 같은가 — 다르면 Skill 도구가 그 이름으로 못 부른다
name="$(sed -n 's/^name:[[:space:]]*//p' "$path" | head -1 | tr -d '"'"'"' ')"
[ "$name" = "$skill" ] || add "frontmatter name($name) 이 폴더 이름($skill) 과 다르다"

# ② description 이 트리거를 잡을 만큼 있는가
desc="$(sed -n '/^description:/,/^[a-z-]*:/p' "$path" | tr -d '\n' | wc -c)"
[ "$desc" -ge 60 ] || add "description 이 너무 짧다(${desc}자) — 언제 쓰는지와 요청 낱말이 안 들어간다"

# ③ 영역 규칙 스킬은 마지막 두 절을 갖는다 — 리뷰가 그 둘만 보고도 되도록
case "$skill" in
    kotlin-* | frontend-*)
        grep -q '^## 적발 신호' "$path" || add "'## 적발 신호' 절이 없다 (kotlin-*·frontend-* 24종의 공통 골격)"
        grep -q '^## 체크리스트' "$path" || add "'## 체크리스트' 절이 없다 (같은 골격)"
        ;;
esac

# ④ 상대 링크가 실제로 있는가 — 옮긴 스킬을 가리키던 링크가 조용히 죽는다
while IFS= read -r link; do
    [ -n "$link" ] || continue
    target="${link%%#*}"
    [ -e "$dir/$target" ] || add "깨진 링크: $link"
done << EOF
$(grep -o '](\.\.\?/[^)]*)' "$path" | sed 's/^](//;s/)$//')
EOF

if [ -n "$problems" ]; then
    head="$skill 에 불변식 위반이 있다:$problems\n"
    label="스킬 점검 — 위반이 있습니다. skill-creator 로 되돌아봅니다."
else
    head=""
    label="스킬을 고쳤습니다 — skill-creator 로 되돌아봅니다."
fi

printf '{"systemMessage":"%s","hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s방금 %s 를 고쳤다. 이 변경을 끝내기 전에 skill-creator 스킬을 호출해 이 파일을 점검하고, 나온 지적 중 고칠 것을 같은 변경에 반영하라. 특히 description 이 이 스킬을 써야 할 상황에서 실제로 걸리는지 본다. 위 불변식 위반이 있으면 그것부터 고친다. 점검 결과는 사용자에게 한 줄로 알린다."}}\n' \
    "$label" "$head" "$path"

exit 0
