#!/usr/bin/env bash
# 계획 루프 회귀 — 계획이 첫 단계부터 끝까지 실제로 도는지 본다.
#
# 사용 (저장소 루트에서):
#   bash common/harness-tests/plan.sh                      # 케이스 전부
#   bash common/harness-tests/plan.sh 'plan>api+web>e2e'   # 이 계획을 끝까지 돌려 보기
#
# 다른 넷과 다른 점: 저기는 규칙 하나에 값을 넣어 답을 보고, 여기는 **여러 바퀴를 이어 돌린다.**
# 한 바퀴씩은 맞는데 이어 돌리면 안 되는 결함이 있다 — 실제로 그런 것을 하나 잡았다.
# 계획 중에는 라운드 값이 넘어오지 않아 상한이 0 이 되고, 라운드 상한을 계획보다 앞에서
# 재는 바람에 루프가 첫 걸음에서 막혔다. 규칙 하나만 보는 케이스로는 안 보였다.
#
# 워크플로와 같은 것을 돌린다 — .github/agent/plan-stage.sh 와 다음 단계 계산까지.
# 여기서 워크플로 셸을 베끼면 베낀 것이 어긋나도 초록불이 된다.
#
# 케이스 형식 (cases/plan/*.case): 머리말만 있고 본문은 없다.
#   # expect: <바퀴마다의 역할을 ' | ' 로 이은 것>   예: plan | api web | e2e
#   # graph: <계획 표현식>
#   # max-steps: <숫자>   # has-pat: true | false   # node: (선택) 단일 노드 우회

set -u

cd "$(dirname "$0")/../.."

PLAN=".github/agent/plan-stage.sh"
CASE_DIR="common/harness-tests/cases/plan"
MAX_TURNS=20 # 루프가 안 멈추는 것을 검사 자체가 붙들고 있지 않게

[ -f "$PLAN" ] || { echo "계획 스크립트가 없어요: $PLAN"; exit 1; }
command -v node >/dev/null || { echo "node 가 필요해요"; exit 1; }

# 계획을 끝까지 돌려 바퀴마다의 역할을 ' | ' 로 이어 낸다.
# 다음 단계 계산(stage+1, step+역할수)은 claude-agent.yml 의 next 잡과 같다.
walk() { # $1=계획 $2=실행상한 $3=PAT $4=단일노드 → 한 줄
    stage=0
    step=0
    turn=0
    trace=""
    while :; do
        turn=$((turn + 1))
        if [ "$turn" -gt "$MAX_TURNS" ]; then
            printf '%s | 안멈춤' "$trace"
            return
        fi
        out=$(CLAUDE_GRAPH="$1" CLAUDE_NODE="$4" STAGE="$stage" STEP="$step" \
            MAX_STEPS="$2" HAS_PAT="$3" bash "$PLAN" 2>/dev/null)
        roles=$(printf '%s\n' "$out" | sed -n 's/^roles=//p')
        has_next=$(printf '%s\n' "$out" | sed -n 's/^has_next=//p')

        [ -z "$trace" ] && trace="$roles" || trace="$trace | $roles"
        [ "$has_next" = "true" ] || break
        stage=$((stage + 1))
        step=$((step + $(printf '%s' "$roles" | wc -w)))
    done
    printf '%s' "$trace"
}

# ── 계획 하나를 끝까지 돌려 보여 준다 ───────────────────────────────
if [ "$#" -gt 0 ]; then
    printf '%s\n' "$(walk "$1" "${2:-12}" "${3:-true}" "${4:-}")"
    exit 0
fi

PASS=0
FAIL=0

for case_file in "$CASE_DIR"/*.case; do
    [ -e "$case_file" ] || continue
    name=$(basename "$case_file" .case)

    head_of() { sed -n "s/^# $1: //p" "$case_file" | head -n 1; }
    expected=$(head_of expect)
    got=$(walk "$(head_of graph)" "$(head_of max-steps)" "$(head_of has-pat)" "$(head_of node)")

    if [ "$got" = "$expected" ]; then
        printf 'PASS  %-30s %s\n' "$name" "$got"
        PASS=$((PASS + 1))
    else
        printf 'FAIL  %-30s\n     │ 기대 %s\n     └ 실제 %s\n' "$name" "$expected" "${got:-응답 없음}"
        FAIL=$((FAIL + 1))
    fi
done

printf '\n%d PASS · %d FAIL\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
