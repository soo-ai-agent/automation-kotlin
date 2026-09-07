#!/usr/bin/env bash
# 형식 검사 — 모델을 부르지 않고 규칙 장치가 성한지만 본다.
#
# 사용 (저장소 루트에서):
#   bash common/harness-tests/static.sh
#
# run.sh 와 나눈 이유: 저기는 케이스 하나가 claude 호출 1건이라 느리고 비싸다.
# 아래 검사들은 문자열 대조로 끝나므로 공짜다. 싼 것을 먼저 돌려 걸러내고,
# 비싼 판정 회귀는 정말 판단이 필요한 것에만 쓴다.
#
# 여기서 잡는 것은 "규칙이 옳은가"가 아니라 **"규칙이 읽히기는 하는가"** 다.
# 링크가 죽거나 경로가 어긋나면 규칙은 파일에 남아 있어도 아무도 안 읽는다.

set -u

cd "$(dirname "$0")/../.."

PASS=0
FAIL=0

ok() {
    printf 'PASS  %s\n' "$1"
    PASS=$((PASS + 1))
}

ng() {
    printf 'FAIL  %s\n     └ %s\n' "$1" "$2"
    FAIL=$((FAIL + 1))
}

# ── ① 케이스 파일마다 기대값이 있는가 ────────────────────────────────
# 첫 줄이 없으면 run.sh 가 빈 기대값으로 대조해 **무조건 통과**시킨다.
# 있으나 마나 한 케이스가 조용히 늘어나는 것을 막는다.
check_case_expectations() {
    bad=""
    for f in common/harness-tests/cases/*/*.diff; do
        [ -e "$f" ] || continue
        head -n 1 "$f" | grep -qE '^# expect: (PASS|CHANGES_REQUESTED)$' || bad="$bad $f"
    done
    if [ -z "$bad" ]; then
        ok "케이스마다 '# expect:' 첫 줄이 있다"
    else
        ng "케이스에 '# expect:' 첫 줄이 없다" "$bad"
    fi
}

# ── ② 영역마다 PASS 기대 케이스가 있는가 ─────────────────────────────
# 차단 기대만 있으면 "전부 막는 리뷰어"도 만점을 받는다. 과잉 차단을 잡을 수 없다.
check_pass_case_per_area() {
    bad=""
    for dir in common/harness-tests/cases/*/; do
        [ -d "$dir" ] || continue
        grep -lqx '# expect: PASS' "$dir"*.diff 2>/dev/null || bad="$bad $dir"
    done
    if [ -z "$bad" ]; then
        ok "영역마다 PASS 기대 케이스가 최소 하나 있다"
    else
        ng "PASS 기대 케이스가 없는 영역이 있다" "$bad"
    fi
}

# ── ③ 스킬 색인의 링크가 살아 있는가 ─────────────────────────────────
# README 는 에이전트가 "어느 스킬을 열지" 고르는 입구다. 링크가 죽으면
# 그 스킬은 파일이 남아 있어도 안 읽힌다.
check_skill_index_links() {
    bad=""
    for readme in .claude/skills/README.md backend/.claude/skills/README.md frontend/.claude/skills/README.md; do
        [ -f "$readme" ] || { bad="$bad $readme(없음)"; continue; }
        dir=$(dirname "$readme")
        targets=$(grep -oE '\]\([^)#:]+\.md\)' "$readme" | sed 's/^](//; s/)$//')
        for t in $targets; do
            # ${} 를 씌운다 — 뒤에 붙는 화살표가 여러 바이트 문자라 $readme 로 쓰면
            # 그 바이트까지 변수 이름으로 먹혀 set -u 에 걸린다.
            [ -f "$dir/$t" ] || bad="$bad ${readme}->${t}"
        done
    done
    if [ -z "$bad" ]; then
        ok "스킬 색인의 링크가 모두 실제 파일을 가리킨다"
    else
        ng "스킬 색인에 죽은 링크가 있다" "$bad"
    fi
}

# ── ④ 하네스 paths 필터가 규칙 문서를 다 덮는가 ──────────────────────
# 규칙 문서를 새 경로에 만들고 이 목록에 안 넣으면, 규칙이 바뀌어도 하네스가
# 돌지 않는다. 안전장치가 꺼진 것을 아무도 모르는 가장 나쁜 실패다.
check_harness_paths_filter() {
    wf=".github/workflows/claude-harness.yml"
    missing=""
    for needed in "**/.claude/skills/**" "common/docs/code-review/rules.md" "CLAUDE.md" "common/harness-tests/**" ".github/agent/review-role.md" ".github/agent/settings.env"; do
        grep -qF "\"$needed\"" "$wf" || missing="$missing $needed"
    done
    if [ -z "$missing" ]; then
        ok "하네스 paths 필터가 규칙 문서를 다 덮는다"
    else
        ng "하네스 paths 필터에 빠진 경로가 있다" "$missing"
    fi
}

# ── ⑤ 리뷰 규칙 경로가 두 곳에서 같은 곳을 가리키는가 ────────────────
# CLAUDE.md 의 @import 와 settings.env 의 CLAUDE_REVIEW_RULES_DIR 이 어긋나면
# 사람이 고친 규칙과 리뷰어가 읽는 규칙이 달라진다.
check_rules_path_agreement() {
    # shellcheck source=/dev/null
    . .github/agent/settings.env
    if grep -q "^@$CLAUDE_REVIEW_RULES_DIR/" CLAUDE.md; then
        ok "CLAUDE.md 의 @import 와 CLAUDE_REVIEW_RULES_DIR 이 같은 곳을 가리킨다"
    else
        ng "CLAUDE.md 의 @import 와 CLAUDE_REVIEW_RULES_DIR 이 어긋난다" \
            "settings.env=$CLAUDE_REVIEW_RULES_DIR, CLAUDE.md 에 그 경로의 @import 가 없다"
    fi
}

# ── ⑥ 리뷰어 역할을 두 소비자가 같은 파일에서 읽는가 ─────────────────
# 실제 리뷰어와 하네스가 각자 프롬프트를 쓰면, 하네스가 통과해도
# 실제 리뷰어의 회귀를 못 잡는다. 이 저장소가 실제로 겪었던 문제다.
check_review_role_shared() {
    # 파일 이름이 어딘가 적혀 있는 것만으로는 부족하다 — 실제로 프롬프트로 넘기는지 본다.
    # (이름만 검사하면 '가져오기만 하고 안 쓰는' 상태를 놓친다. 변이로 확인했다.)
    role=".github/agent/review-role.md"
    missing=""
    [ -f "$role" ] || missing="$missing $role(없음)"
    grep -qF 'cat /tmp/review-role.md' .github/workflows/claude-review.yml \
        || missing="$missing claude-review.yml(역할파일을_프롬프트로_안넘김)"
    grep -qF 'ROLE_FILE=".github/agent/review-role.md"' common/harness-tests/run.sh \
        || missing="$missing run.sh(역할파일을_안가리킴)"
    grep -qF 'cat "$ROLE_FILE"' common/harness-tests/run.sh \
        || missing="$missing run.sh(역할파일을_프롬프트로_안넘김)"
    if [ -z "$missing" ]; then
        ok "실제 리뷰어와 하네스가 같은 역할 지시문을 읽는다"
    else
        ng "리뷰어 역할 지시문을 공유하지 않는 곳이 있다" "$missing"
    fi
}

check_case_expectations
check_pass_case_per_area
check_skill_index_links
check_harness_paths_filter
check_rules_path_agreement
check_review_role_shared

printf '\n%d PASS · %d FAIL\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
