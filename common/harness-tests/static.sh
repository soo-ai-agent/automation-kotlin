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
# 기대값이 없으면 러너가 빈 값으로 대조해 **무조건 통과**시킨다.
# 있으나 마나 한 케이스가 조용히 늘어나는 것을 막는다.
#
# 케이스는 두 종류다 — 판정 케이스(.diff, run.sh 가 모델에게 묻는다)와
# 그래프 케이스(.case, graph.sh 가 모델 없이 펼쳐 본다). 기대값의 꼴이 다르다.
check_case_expectations() {
    bad=""
    for f in common/harness-tests/cases/*/*.diff; do
        [ -e "$f" ] || continue
        head -n 1 "$f" | grep -qE '^# expect: (PASS|CHANGES_REQUESTED)$' || bad="$bad $f"
    done
    for f in common/harness-tests/cases/graph/*.case; do
        [ -e "$f" ] || continue
        grep -qE '^# expect: (PASS|FAIL)$' "$f" || bad="$bad $f(expect없음)"
        grep -q '^# graph: ' "$f" || bad="$bad $f(graph없음)"
    done
    if [ -z "$bad" ]; then
        ok "케이스마다 '# expect:' 기대값이 있다"
    else
        ng "케이스에 기대값이 없다" "$bad"
    fi
}

# ── ② 영역마다 PASS 기대 케이스가 있는가 ─────────────────────────────
# 차단 기대만 있으면 "전부 막는 리뷰어"도 만점을 받는다. 과잉 차단을 잡을 수 없다.
#
# 판정 케이스(.diff)를 담은 영역만 본다 — 그래프 케이스에는 '과잉 차단'이라는 것이 없다.
check_pass_case_per_area() {
    bad=""
    for dir in common/harness-tests/cases/*/; do
        [ -d "$dir" ] || continue
        ls "$dir"*.diff >/dev/null 2>&1 || continue
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
    for needed in "**/.claude/skills/**" "common/docs/code-review/rules.md" "CLAUDE.md" "common/harness-tests/**" ".github/agent/review-role.md" ".github/agent/settings.env" ".github/agent/nodes/**" ".github/agent/run-claude.sh" ".github/agent/graph.js" ".github/workflows/claude-agent.yml" ".github/agent/loop-decision.sh" ".github/workflows/claude-review.yml"; do
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

# ── ⑦ 노드마다 실행 계약이 있고, 그것이 실제로 적용되는가 ────────────
# 노드 파일 앞머리의 `allowed-tools:` 가 그 역할에 허용할 명령을 정한다.
# 계약이 없으면 run-claude.sh 는 읽기 전용 git 만 준다 — 그 노드는 커밋도 검증도 못 하는데
# 지시문은 "커밋해라"라고 말하는 상태가 된다. 조용히 어긋나기 전에 여기서 막는다.
#
# 파일에 계약을 적어 두는 것만으로는 부족하다 — run-claude.sh 가 그것을 읽어 쓰는지까지 본다.
# (⑥ 에서 배운 것과 같다: 가져오기만 하고 안 쓰는 상태를 이름 검사로는 못 잡는다.)
check_node_contracts() {
    bad=""
    for f in .github/agent/nodes/*.md; do
        [ -e "$f" ] || continue
        name=$(basename "$f")
        if [ "$(head -n 1 "$f")" != "---" ]; then
            bad="$bad ${name}(계약없음)"
            continue
        fi
        if [ "$(grep -c '^---$' "$f")" -lt 2 ]; then
            bad="$bad ${name}(닫는---없음)"
            continue
        fi
        grep -q '^allowed-tools:' "$f" || bad="$bad ${name}(allowed-tools없음)"
    done

    runner=".github/agent/run-claude.sh"
    # 줄 시작을 앵커로 잡는다 — 고정 문자열만 찾으면 주석 처리된 줄에도 걸려 변이를 놓친다
    grep -qE '^[[:space:]]*apply_contract /tmp/role\.md$' "$runner" \
        || bad="$bad run-claude.sh(계약을_안읽음)"
    grep -qE '^[[:space:]]*apply_contract /tmp/rescue-role\.md$' "$runner" \
        || bad="$bad run-claude.sh(수습노드에_계약을_안읽음)"
    # 패턴이 -- 로 시작해 grep 이 옵션으로 먹는다 — 인자 끝 표시를 붙인다
    grep -qF -e '--allowedTools "$ALLOWED"' "$runner" || bad="$bad run-claude.sh(계약을_CLI에_안넘김)"

    if [ -z "$bad" ]; then
        ok "노드마다 실행 계약이 있고 run-claude.sh 가 그것을 적용한다"
    else
        ng "노드 실행 계약이 없거나 적용되지 않는다" "$bad"
    fi
}

# ── ⑧ 그래프의 단계 수와 단계 잡이 맞는가 ────────────────────────────
# 순차 단계 상한은 두 곳에 있다 — graph.js 의 MAX_STAGES 와 claude-agent.yml 에
# 미리 선언해 둔 단계 잡(s1..sN). GitHub Actions 가 잡을 실행 중에 만들 수 없어서
# 어쩔 수 없이 나뉘어 있는 값이라, 어긋나면 그래프가 펼쳐지고도 돌 잡이 없다.
#
# 단계 잡의 `with:` 블록도 함께 본다. 네 잡은 세 줄(needs·if·include)만 다르고
# 나머지는 같아야 하는데, 하나만 고치면 그 단계만 다른 입력으로 돈다.
check_graph_stage_jobs() {
    wf=".github/workflows/claude-agent.yml"
    max=$(sed -n 's/^const MAX_STAGES = \([0-9][0-9]*\).*/\1/p' .github/agent/graph.js)
    jobs=$(grep -cE '^  s[0-9]+:$' "$wf")

    bad=""
    [ -n "$max" ] || bad="$bad graph.js(MAX_STAGES를_못읽음)"
    [ "$max" = "$jobs" ] || bad="$bad MAX_STAGES=$max≠단계잡=$jobs"

    # with: 블록을 잡마다 파일로 뽑아 첫 번째와 대조한다
    tmp=$(mktemp -d)
    awk -v dir="$tmp" '
        /^    with:$/ { n++; inb = 1; next }
        inb && /^      / { print > (dir "/" n); next }
        inb { inb = 0 }
    ' "$wf"
    if [ -f "$tmp/1" ]; then
        i=2
        while [ -f "$tmp/$i" ]; do
            cmp -s "$tmp/1" "$tmp/$i" || bad="$bad s${i}(with블록이_s1과_다름)"
            i=$((i + 1))
        done
    else
        bad="$bad $wf(with블록을_못찾음)"
    fi
    rm -rf "$tmp"

    if [ -z "$bad" ]; then
        ok "그래프 단계 상한($max)과 단계 잡 수가 같고, 단계 잡의 with 블록이 모두 같다"
    else
        ng "그래프 단계 선언이 어긋난다" "$bad"
    fi
}

# ── ⑨ 루프 판단을 실제 리뷰어와 하네스가 같은 파일에서 읽는가 ────────
# ⑥ 과 같은 이유다 — 판단이 워크플로 셸로 되돌아가면 하네스가 루프를 돌려 볼 수 없고,
# 하네스가 통과해도 실제 루프의 회귀는 못 잡는다.
#
# 자동 머지 게이트가 그 판단 안에 있어서, 되돌아간 것을 모르고 지나가면 가장 비싸다.
check_loop_decision_shared() {
    decide=".github/agent/loop-decision.sh"
    wf=".github/workflows/claude-review.yml"
    bad=""
    [ -f "$decide" ] || bad="$bad $decide(없음)"
    grep -qF "origin/\$BASE_REF:.github/agent/loop-decision.sh" "$wf" \
        || bad="$bad claude-review.yml(기준_브랜치에서_안꺼냄)"
    grep -qE '^[[:space:]]*DECISION=.*bash /tmp/loop-decision\.sh' "$wf" \
        || bad="$bad claude-review.yml(결정을_스크립트에_안물음)"
    grep -qF 'DECIDE=".github/agent/loop-decision.sh"' common/harness-tests/loop.sh \
        || bad="$bad harness-tests/loop.sh(같은_파일을_안가리킴)"

    # 물어보고 답을 버리면 판단이 되돌아간 것과 같다 — 결정대로 실행하는지까지 본다
    grep -qF 'case "$DECISION" in' "$wf" \
        || bad="$bad claude-review.yml(결정대로_실행하지_않음)"

    if [ -z "$bad" ]; then
        ok "실제 리뷰어와 하네스가 같은 루프 판단 스크립트를 쓴다"
    else
        ng "루프 판단이 공유되지 않거나 워크플로로 되돌아갔다" "$bad"
    fi
}

check_case_expectations
check_pass_case_per_area
check_skill_index_links
check_harness_paths_filter
check_rules_path_agreement
check_review_role_shared
check_node_contracts
check_graph_stage_jobs
check_loop_decision_shared

printf '\n%d PASS · %d FAIL\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
