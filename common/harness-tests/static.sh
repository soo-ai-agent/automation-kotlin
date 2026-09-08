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
    for f in common/harness-tests/cases/*/*.case; do
        [ -e "$f" ] || continue
        grep -q '^# run: ' "$f" || bad="$bad $f(run없음)"
        grep -qE '^# expect(-stderr)?: ' "$f" || bad="$bad $f(expect없음)"
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
    for needed in "**/.claude/skills/**" "common/docs/code-review/rules.md" "CLAUDE.md" "common/harness-tests/**" ".github/agent/review-role.md" ".github/agent/settings.env" ".github/agent/nodes/**" ".github/agent/run-claude.sh" ".github/agent/graph.js" ".github/workflows/claude-agent.yml" ".github/agent/loop-decision.sh" ".github/workflows/claude-review.yml" ".github/agent/state.sh" ".github/workflows/claude-node.yml" ".github/agent/next-role.sh" ".github/agent/plan-stage.sh" ".github/agent/dispatch_rules.py" ".github/agent/dispatch.py"; do
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
    # 비교용 워크플로가 있는 동안에는 그것도 같은 역할 파일을 읽어야 한다 —
    # 자기 프롬프트를 따로 쓰면 무엇을 비교하는지 알 수 없게 된다.
    # 비교가 끝나 파일을 지우면 이 검사도 함께 사라진다.
    compare=".github/workflows/claude-review-compare.yml"
    if [ -f "$compare" ]; then
        grep -qF "origin/\$BASE_REF:.github/agent/review-role.md" "$compare" \
            || missing="$missing claude-review-compare.yml(역할파일을_안읽음)"
    fi
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
        grep -q '^add-dir:' "$f" || bad="$bad ${name}(add-dir없음)"
        # 네이티브 에이전트 형식이어야 --agent 로 부를 수 있다. 이름은 파일 이름과 같아야
        # 하고(실행기가 NODE_NAME 으로 부른다), tools 는 Claude Code 가 강제한다.
        [ "$(sed -n 's/^name: //p' "$f" | head -n 1)" = "$(basename "$f" .md)" ] \
            || bad="$bad ${name}(name이_파일이름과_다름)"
        grep -q '^tools:' "$f" || bad="$bad ${name}(tools없음)"
        # 코드를 커밋하는 역할은 영역 스킬 없이 돌면 안 된다 — 리뷰어는 그 스킬로 판정하는데
        # 작성자는 그 스킬을 못 보는 상태가 된다. 실제로 그 상태였다.
        if grep -q 'git commit' "$f" && [ -z "$(sed -n 's/^add-dir: *//p' "$f")" ]; then
            bad="$bad ${name}(커밋하는데_영역스킬이_없음)"
        fi
    done

    runner=".github/agent/run-claude.sh"
    # 줄 시작을 앵커로 잡는다 — 고정 문자열만 찾으면 주석 처리된 줄에도 걸려 변이를 놓친다
    grep -qE '^[[:space:]]*apply_contract /tmp/role\.md$' "$runner" \
        || bad="$bad run-claude.sh(계약을_안읽음)"
    grep -qE '^[[:space:]]*apply_contract /tmp/rescue-role\.md$' "$runner" \
        || bad="$bad run-claude.sh(수습노드에_계약을_안읽음)"
    # 패턴이 -- 로 시작해 grep 이 옵션으로 먹는다 — 인자 끝 표시를 붙인다
    grep -qF -e '--allowedTools "$ALLOWED"' "$runner" || bad="$bad run-claude.sh(계약을_CLI에_안넘김)"
    # 루트에서 열면 하위 폴더의 kotlin-*·frontend-* 가 세션 스킬 목록에 안 오른다.
    # 실측: --add-dir 없이 0개, 붙이면 17개·8개 (bin/claude-skills.sh 에도 같은 기록이 있다).
    grep -qF 'claude --agent "$AGENT" $ADD_DIRS -p' "$runner" \
        || bad="$bad run-claude.sh(영역스킬을_안붙이거나_에이전트로_안부름)"
    # 역할 파일은 기준 브랜치 것을 홈에 놓는다. 작업 트리의 .claude/agents/ 를 쓰면
    # 작업 브랜치가 자기 역할을 덮어써 권한을 넓힐 수 있다.
    grep -qF 'cp "$1" ~/.claude/agents/' "$runner" || bad="$bad run-claude.sh(역할을_에이전트_자리에_안놓음)"
    # 로컬 세션은 launcher 가 .claude/agents/ 로 복사해 쓴다. 그건 사본이라 괜찮지만
    # **커밋되면 안 된다** — 커밋되는 순간 작업 브랜치가 자기 역할을 고칠 수 있다.
    git check-ignore -q .claude/agents 2>/dev/null \
        || bad="$bad .claude/agents가_gitignore에_없음(커밋되면_역할을_고칠_수_있다)"
    git ls-files --error-unmatch .claude/agents >/dev/null 2>&1 \
        && bad="$bad .claude/agents가_커밋됨"

    if [ -z "$bad" ]; then
        ok "노드가 네이티브 에이전트 형식이고 run-claude.sh 가 --agent 로 부른다"
    else
        ng "노드 실행 계약이 없거나 적용되지 않는다" "$bad"
    fi
}

# ── ⑧ 계획이 잡을 미리 선언하지 않고 루프로 도는가 ───────────────────
# 예전에는 단계마다 잡(s1..s4)을 선언해 두고 graph.js 의 MAX_STAGES 로 맞췄다.
# 그래서 순차 단계가 4개로 막혔고, 같은 with 블록이 네 벌 복사돼 있었다.
#
# 지금은 잡 하나가 이번 단계를 돌린 뒤 자기를 다시 부른다. 되돌아가면 상한이 되살아나므로
# 그 흔적을 막는다 — 단계 잡 선언, MAX_STAGES, 그리고 재호출이 사라지는 것.
check_graph_loop_shape() {
    wf=".github/workflows/claude-agent.yml"
    bad=""
    n=$(grep -cE '^  s[0-9]+:$' "$wf")
    [ "$n" = "0" ] || bad="$bad claude-agent.yml(단계_잡을_미리_선언함:$n개)"
    grep -q 'MAX_STAGES' .github/agent/graph.js && bad="$bad graph.js(단계_상한이_되살아남)"
    grep -qF 'gh workflow run claude-agent.yml' "$wf" \
        || bad="$bad claude-agent.yml(자기를_다시_안부름)"
    grep -qF 'bash .github/agent/plan-stage.sh' "$wf" \
        || bad="$bad claude-agent.yml(계획_계산을_스크립트에_안맡김)"
    grep -qF 'bash .github/agent/next-role.sh' .github/agent/plan-stage.sh \
        || bad="$bad plan-stage.sh(계속할지를_규칙에_안물음)"
    grep -qF 'bash .github/agent/plan-stage.sh' common/harness-tests/cases.sh \
        || bad="$bad cases.sh(계획을_안가리킴)"
    # 계획 계산이 워크플로 셸로 돌아오면 하네스가 그것을 베껴 쓰게 된다
    grep -qF 'node .github/agent/graph.js' "$wf" \
        && bad="$bad claude-agent.yml(계획_계산이_셸로_되돌아옴)"
    # 병렬은 matrix 로 살아 있어야 한다 — 없으면 api+web 이 순차로 떨어진다
    grep -qF 'include: ${{ fromJSON(needs.plan.outputs.matrix) }}' "$wf" \
        || bad="$bad claude-agent.yml(병렬_matrix_가_없음)"

    if [ -z "$bad" ]; then
        ok "계획이 잡을 미리 선언하지 않고, 루프가 자기를 다시 부르며, 병렬이 살아 있다"
    else
        ng "계획 실행이 정적 구조로 되돌아갔다" "$bad"
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
    grep -qE '^[[:space:]]*MERGE=' "$wf" \
        || bad="$bad claude-review.yml(머지_결정을_스크립트에_안물음)"
    grep -qrF 'bash .github/agent/loop-decision.sh' common/harness-tests/cases/loop/ \
        || bad="$bad cases/loop(같은_파일을_안가리킴)"

    # 물어보고 답을 버리면 판단이 되돌아간 것과 같다 — 결정대로 실행하는지까지 본다
    grep -qF 'case "$MERGE" in' "$wf" \
        || bad="$bad claude-review.yml(머지_결정대로_실행하지_않음)"

    if [ -z "$bad" ]; then
        ok "실제 리뷰어와 하네스가 같은 루프 판단 스크립트를 쓴다"
    else
        ng "루프 판단이 공유되지 않거나 워크플로로 되돌아갔다" "$bad"
    fi
}

# ── ⑩ 루프 상태를 세 소비자가 같은 도구로 읽고 쓰는가 ────────────────
# ⑥·⑨ 와 같은 이유다. 상태는 노드·리뷰어·하네스 셋이 함께 쓰는 값이라,
# 한 곳이 자기 방식으로 코멘트를 파싱하기 시작하면 그 순간 원본이 둘이 된다.
#
# 도구가 GitHub API 를 부르기 시작해도 같은 일이 벌어진다 — 하네스가 못 돌린다.
check_state_shared() {
    state=".github/agent/state.sh"
    bad=""
    [ -f "$state" ] || bad="$bad $state(없음)"

    grep -qF "origin/\$DEF:.github/agent/state.sh" .github/workflows/claude-node.yml \
        || bad="$bad claude-node.yml(기본_브랜치에서_안꺼냄)"
    grep -qF 'bash /tmp/state.sh merge' .github/workflows/claude-node.yml \
        || bad="$bad claude-node.yml(상태를_안씀)"
    grep -qF "origin/\$BASE_REF:.github/agent/state.sh" .github/workflows/claude-review.yml \
        || bad="$bad claude-review.yml(기준_브랜치에서_안꺼냄)"
    grep -qF 'bash /tmp/state.sh merge' .github/workflows/claude-review.yml \
        || bad="$bad claude-review.yml(상태를_안씀)"
    grep -qrF 'bash .github/agent/state.sh' common/harness-tests/cases/state/ \
        || bad="$bad cases/state(같은_파일을_안가리킴)"

    # 도구 안에 GitHub 호출이 들어오면 하네스가 상태를 돌려 볼 수 없게 된다
    grep -qE '^[[:space:]]*(gh|curl) ' "$state" && bad="$bad state.sh(GitHub_호출이_들어옴)"

    if [ -z "$bad" ]; then
        ok "노드·리뷰어·하네스가 같은 상태 도구를 쓰고, 그 도구는 GitHub 를 안 부른다"
    else
        ng "루프 상태가 한 곳에서 관리되지 않는다" "$bad"
    fi
}

# ── ⑪ 전이 규칙을 리뷰어와 하네스가 같은 파일로 쓰는가 ────────────────
# 리뷰어는 역할 이름을 상수로 박지 않고 이 규칙에 물어봐야 한다. 되돌아가면
# 상황을 볼 자리가 다시 사라지고, 하네스가 아무리 통과해도 실제 루프는 그대로다.
check_next_role_testable() {
    next=".github/agent/next-role.sh"
    wf=".github/workflows/claude-review.yml"
    bad=""
    [ -f "$next" ] || bad="$bad $next(없음)"
    grep -qrF 'bash .github/agent/next-role.sh' common/harness-tests/cases/next-role/ \
        || bad="$bad cases/next-role(같은_파일을_안가리킴)"
    grep -qE '^[[:space:]]*(gh|curl|git) ' "$next" && bad="$bad next-role.sh(바깥을_부름)"

    grep -qF "origin/\$BASE_REF:.github/agent/next-role.sh" "$wf" \
        || bad="$bad claude-review.yml(기준_브랜치에서_안꺼냄)"
    grep -qE '^[[:space:]]*ROLE=' "$wf" || bad="$bad claude-review.yml(역할을_안물음)"
    grep -qF 'case "$ROLE" in' "$wf" || bad="$bad claude-review.yml(역할대로_실행하지_않음)"
    # 역할 이름을 상수로 박아 두면 규칙에 물어본 답이 버려진다
    grep -qE 'node="(fix|code|plan|split|test|e2e|api|web)"' "$wf" \
        && bad="$bad claude-review.yml(역할_이름이_상수로_박힘)"

    # 규칙이 늘어도 낼 수 있는 값은 셋뿐이다 — done · human · 역할 이름.
    # 역할 이름을 내놓으려면 그 역할 파일이 있어야 한다.
    for role in $(sed -n 's/^[[:space:]]*echo "\([a-z][a-z0-9_]*\)"$/\1/p' "$next" | sort -u); do
        case "$role" in
            done | human) continue ;;
        esac
        [ -f ".github/agent/nodes/$role.md" ] || bad="$bad next-role.sh(없는_역할:$role)"
    done

    if [ -z "$bad" ]; then
        ok "전이 규칙이 값만 받는 스크립트이고, 내놓는 역할이 모두 실재한다"
    else
        ng "전이 규칙을 하네스가 잴 수 없다" "$bad"
    fi
}

# ── ⑫ 판정 케이스가 자기 영역 파일만 건드리는가 ─────────────────────
# 영역 폴더는 `run.sh backend` 처럼 어느 케이스를 돌릴지 고르는 데 쓴다.
# cases/backend/ 에 프론트 diff 가 들어 있으면 `run.sh frontend` 를 돌린 사람은
# 그 케이스가 조용히 빠진 것을 모른다.
check_case_area_match() {
    bad=""
    for dir in common/harness-tests/cases/backend common/harness-tests/cases/frontend; do
        area=$(basename "$dir")
        for f in "$dir"/*.diff; do
            [ -e "$f" ] || continue
            # diff 머리말에서 파일 경로를 뽑아 영역 이름으로 시작하는지 본다
            for path in $(sed -n 's|^+++ b/||p;s|^--- a/||p' "$f" | sort -u); do
                case "$path" in
                    "$area"/*) ;;
                    /dev/null) ;;
                    *) bad="$bad $(basename "$f")->$path" ;;
                esac
            done
        done
    done
    if [ -z "$bad" ]; then
        ok "판정 케이스가 자기 영역 파일만 건드린다"
    else
        ng "케이스가 다른 영역 파일을 건드린다" "$bad"
    fi
}

# ── ⑬ 실행 코드에 문법 오류가 없는가 ────────────────────────────────
# 셸과 js 는 컴파일이 없어서 문법 오류가 실행 시점에야 드러난다. 노드가 40분 돌다가
# 마지막 줄에서 깨지는 것보다, 여기서 1초에 잡는 편이 낫다.
#
# 문법만 본다. 무엇을 하는지는 각 도구의 회귀 검사(graph.sh·loop.sh·state.sh·
# next-role.sh·plan.sh)가 값을 넣어 답을 대조한다.
check_syntax() {
    bad=""
    for f in .github/agent/*.sh common/harness-tests/*.sh; do
        [ -e "$f" ] || continue
        bash -n "$f" 2>/dev/null || bad="$bad $(basename "$f")"
    done
    for f in .github/agent/*.js; do
        [ -e "$f" ] || continue
        node --check "$f" >/dev/null 2>&1 || bad="$bad $(basename "$f")"
    done
    for f in .github/agent/*.py; do
        [ -e "$f" ] || continue
        python3 -m py_compile "$f" 2>/dev/null || bad="$bad $(basename "$f")"
    done
    rm -rf .github/agent/__pycache__

    if [ -z "$bad" ]; then
        ok "실행 코드에 문법 오류가 없다"
    else
        ng "문법 오류가 있다" "$bad"
    fi
}

# ── ⑭ 디스패처가 판단을 규칙에 맡기는가 ──────────────────────────────
# 이슈를 닫고 PR 을 닫고 브랜치를 지우는 판단이다. 틀리면 사람이 만든 것이 사라진다.
# 판단이 dispatch.py 안으로 되돌아가면 하네스가 못 재고, 그 상태로 10분마다 돈다.
check_dispatch_rules_shared() {
    rules=".github/agent/dispatch_rules.py"
    dp=".github/agent/dispatch.py"
    bad=""
    [ -f "$rules" ] || bad="$bad $rules(없음)"
    grep -qF 'import dispatch_rules' "$dp" || bad="$bad dispatch.py(규칙을_안가져옴)"
    for fn in start_issue close_pr delete_branch issue_of; do
        grep -qF "dispatch_rules.$fn" "$dp" || bad="$bad dispatch.py(${fn}_를_안물음)"
    done
    grep -qrF 'python3 .github/agent/dispatch_rules.py' common/harness-tests/cases/dispatch/ \
        || bad="$bad cases/dispatch(같은_파일을_안가리킴)"
    # 규칙 안에서 바깥을 부르면 하네스가 못 돌린다
    grep -qE '^[[:space:]]*(import (urllib|requests|subprocess)|from (urllib|subprocess))' "$rules" \
        && bad="$bad dispatch_rules.py(바깥을_부름)"

    if [ -z "$bad" ]; then
        ok "디스패처가 지우는 판단을 규칙에 맡기고, 그 규칙은 바깥을 안 부른다"
    else
        ng "디스패처 판단이 한 곳에서 관리되지 않는다" "$bad"
    fi
}

# ── ⑮ 리뷰어가 읽기만 하고, 토큰을 못 만지는가 ────────────────────────
# 리뷰어는 코드를 고치지 않는다. 그런데 지시문으로만 말하고 도구는 전부 열려 있었다 —
# Bash 가 있고 GH_TOKEN 이 잡 레벨에 있어서, 모델이 gh 를 불러 AGENT_PAT 권한을
# 쓸 수 있었다. claude-node.yml 이 지키던 규칙인데 리뷰어만 어기고 있었다.
#
# 하네스도 같은 제한으로 부른다 — 안 맞추면 하네스가 실제 리뷰어를 재지 못한다.
check_reviewer_readonly() {
    wf=".github/workflows/claude-review.yml"
    bad=""
    grep -qF -e '--allowedTools "Read,Grep,Glob"' "$wf" \
        || bad="$bad claude-review.yml(도구를_안좁힘)"
    grep -qF -e '--allowedTools "Read,Grep,Glob"' common/harness-tests/run.sh \
        || bad="$bad run.sh(같은_제한으로_안부름)"

    # GH_TOKEN 이 잡 레벨에 있으면 claude 를 돌리는 step 도 갖게 된다.
    # 잡 레벨 env 는 들여쓰기 6칸, step 의 env 는 10칸이라 그것으로 가른다.
    grep -qE '^      GH_TOKEN:' "$wf" && bad="$bad claude-review.yml(GH_TOKEN이_잡_레벨)"

    if [ -z "$bad" ]; then
        ok "리뷰어가 읽기 도구만 쓰고 GH_TOKEN 을 step 에만 건다"
    else
        ng "리뷰어가 필요 이상의 권한으로 돈다" "$bad"
    fi
}

# ── ⑯ 로컬 워크플로가 부르는 역할이 실재하는가 ────────────────────────
# .claude/workflows/work.js 는 노드 역할을 agentType 으로 부른다. 계획 표현식에
# 없는 역할을 적으면 그 단계가 통째로 죽는데, 워크플로는 모델을 부르는 물건이라
# 돌려 보기 전에는 안 드러난다. 이름만이라도 여기서 맞춘다.
check_workflow_roles() {
    wf=".claude/workflows/work.js"
    [ -f "$wf" ] || { ok "로컬 워크플로 없음 — 검사 건너뜀"; return; }
    bad=""
    node --check "$wf" 2>/dev/null || bad="$bad work.js(문법오류)"
    # 스크립트가 역할 이름을 직접 적지 않고 계획 표현식에서 받으므로,
    # 기본값으로 쓰는 것과 문서에 예로 든 것이 실재하는지만 본다.
    for role in $(sed -n "s/.*args.plan) || '\([a-z>+]*\)'.*/\1/p" "$wf" | tr '>+' '  '); do
        [ -f ".github/agent/nodes/$role.md" ] || bad="$bad work.js(없는_역할:$role)"
    done
    grep -qF 'agentType: role' "$wf" || bad="$bad work.js(역할을_agentType으로_안부름)"

    if [ -z "$bad" ]; then
        ok "로컬 워크플로가 실재하는 역할을 agentType 으로 부른다"
    else
        ng "로컬 워크플로가 어긋난다" "$bad"
    fi
}

check_case_expectations
check_pass_case_per_area
check_skill_index_links
check_harness_paths_filter
check_rules_path_agreement
check_review_role_shared
check_node_contracts
check_graph_loop_shape
check_loop_decision_shared
check_state_shared
check_next_role_testable
check_case_area_match
check_syntax
check_dispatch_rules_shared
check_reviewer_readonly
check_workflow_roles

printf '\n%d PASS · %d FAIL\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
