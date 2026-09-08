#!/usr/bin/env bash
# 머지 회귀 — 리뷰를 통과한 PR 을 머지할지 사람에게 넘길지 본다.
#
# 사용 (저장소 루트에서):
#   bash common/harness-tests/loop.sh          # 케이스 전부
#   bash common/harness-tests/loop.sh table    # 상황별 머지 결정을 표로 뽑아 보기
#
# 두 번째 꼴은 머지 게이트를 고치기 전에 쓴다. 조건을 더하거나 순서를 바꾸기 전에
# 지금 어떤 상황이 어떤 결정으로 떨어지는지 한 번에 본다. PR 도 모델도 필요 없다.
#
# 재작업(어느 역할을 부를지)은 여기가 아니라 next-role.sh 가 정한다.
#
# graph.sh 와 짝이다 — 둘 다 **동작을 재지만 모델을 부르지 않는다.**
# 잴 수 있는 이유는 판단이 워크플로 셸이 아니라 .github/agent/loop-decision.sh 에
# 값만 받는 스크립트로 나와 있기 때문이다. 거기로 되돌리면 이 검사는 죽는다.
#
# 케이스 형식 (cases/loop/*.case): 머리말만 있고 본문은 없다.
#   # expect: merge | human-merge | no-merge
#   # verdict: PASS | CHANGES_REQUESTED | (빈 값)
#   # head-ref: <브랜치 이름>
#   # agent-made: true | false | unknown

set -u

cd "$(dirname "$0")/../.."

DECIDE=".github/agent/loop-decision.sh"
CASE_DIR="common/harness-tests/cases/loop"

[ -f "$DECIDE" ] || { echo "루프 판단 스크립트가 없어요: $DECIDE"; exit 1; }

decide() { # $1=판정 $2=브랜치 $3=라벨
    VERDICT="$1" HEAD_REF="$2" AGENT_MADE="$3" bash "$DECIDE"
}

# ── 상황별 결정을 표로 뽑는다 ───────────────────────────────────────
if [ "${1:-}" = "table" ]; then
    printf '%-18s %-22s %-11s → %s\n' 판정 브랜치 claude-made 결정
    for verdict in PASS CHANGES_REQUESTED; do
        for ref in claude/issue-42 feat/hand-written; do
            for made in true false unknown; do
                printf '%-18s %-22s %-11s → %s\n' \
                    "$verdict" "$ref" "$made" "$(decide "$verdict" "$ref" "$made")"
            done
        done
    done
    exit 0
fi

PASS=0
FAIL=0

for case_file in "$CASE_DIR"/*.case; do
    [ -e "$case_file" ] || continue
    name=$(basename "$case_file" .case)

    head_of() { sed -n "s/^# $1: //p" "$case_file" | head -n 1; }
    expected=$(head_of expect)
    got=$(decide "$(head_of verdict)" "$(head_of head-ref)" "$(head_of agent-made)")

    if [ "$got" = "$expected" ]; then
        printf 'PASS  %-34s %s\n' "$name" "$got"
        PASS=$((PASS + 1))
    else
        printf 'FAIL  %-34s 기대=%s 실제=%s\n' "$name" "$expected" "${got:-응답 없음}"
        FAIL=$((FAIL + 1))
    fi
done

printf '\n%d PASS · %d FAIL\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
