#!/usr/bin/env bash
# 🔒 기능 본체 — 계획의 이번 단계를 정하는 곳. claude-agent.yml 의 plan 잡이 부른다.
#
# 하는 일은 셋이다.
#   1. graph.js 로 계획 전체를 펼친다
#   2. 이번 단계(STAGE)의 역할들을 꺼내 next-role.sh 에게 계속해도 되는지 묻는다
#   3. 돌릴 매트릭스와 다음 단계가 남았는지를 낸다
#
# 여기에는 GitHub API 호출도 파일 쓰기도 없다. 값을 받아 값을 낸다.
# 그래야 하네스가 GitHub 없이 루프를 끝까지 돌려 볼 수 있다
# (tests/cases.sh — 케이스는 cases/plan/).
#
# **워크플로가 이 계산을 자기 셸에 두면 안 된다.** 그러면 하네스가 그것을 베껴 쓰게 되고,
# 베낀 것이 어긋나도 하네스는 초록불이다. 리뷰어에서 겪었던 문제와 같다.
#
# 받는 값 (환경변수):
#   CLAUDE_GRAPH  계획 표현식 (예: plan>code?fix>test)
#   CLAUDE_NODE   (선택) 이 노드 하나만 — 계획을 무시한다
#   STAGE         이번이 계획의 몇 번째 단계인지 (0부터)
#   STEP          지금까지 노드가 돈 횟수
#   MAX_STEPS     그 상한
#   HAS_PAT       true | false
#
# 내는 값 (stdout, key=value 줄):
#   roles=<공백 구분한 역할들, 또는 done | human | loop-off>
#   matrix=<이번에 돌릴 노드들의 JSON. 돌 것이 없으면 []>
#   has_next=<true | false>
#
# 멈춘 이유는 next-role.sh 가 stderr 로 내는 것을 그대로 흘려보낸다.

set -u

cd "$(dirname "$0")/../.."

STAGE="${STAGE:-0}"
STEP="${STEP:-0}"
MAX_STEPS="${MAX_STEPS:-0}"
HAS_PAT="${HAS_PAT:-false}"

stages=$(env -u GITHUB_OUTPUT node .github/agent/graph.js) || exit $?
stages=$(printf '%s' "$stages" | sed -n 's/^stages=//p')
[ -n "$stages" ] || { echo "plan-stage: graph.js 가 stages 를 내지 않았어요" >&2; exit 1; }

# 이번 단계와 다음 단계를 꺼낸다. 다음이 비어 있으면 이번이 마지막이다.
pick_stage() { # $1=몇 번째
    printf '%s' "$stages" | AT="$1" node -e '
        const all = JSON.parse(require("fs").readFileSync(0, "utf8"));
        process.stdout.write(JSON.stringify(all[Number(process.env.AT)] || []));'
}

this_stage=$(pick_stage "$STAGE")
next_stage=$(pick_stage "$((STAGE + 1))")
stage_roles=$(printf '%s' "$this_stage" | node -e '
    const s = JSON.parse(require("fs").readFileSync(0, "utf8"));
    process.stdout.write(s.map((n) => n.node).join(" "));')

# 계속할지는 next-role.sh 가 정한다 — 상한도 상태도 거기서 잰다.
# 계획을 밟는 중이라 판정(VERDICT)은 넘기지 않는다.
roles=$(STAGE_ROLES="$stage_roles" STEP="$STEP" MAX_STEPS="$MAX_STEPS" HAS_PAT="$HAS_PAT" \
    bash .github/agent/next-role.sh)

case "$roles" in
    done | human | loop-off)
        matrix="[]"
        has_next=false
        ;;
    *)
        matrix="$this_stage"
        if [ "$next_stage" = "[]" ]; then has_next=false; else has_next=true; fi
        ;;
esac

printf 'roles=%s\n' "$roles"
printf 'matrix=%s\n' "$matrix"
printf 'has_next=%s\n' "$has_next"
