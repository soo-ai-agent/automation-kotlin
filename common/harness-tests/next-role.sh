#!/usr/bin/env bash
# 전이 회귀 — 리뷰 뒤에 어느 역할을 부를지 정하는 규칙이 상황마다 맞는지 본다.
#
# 사용 (저장소 루트에서):
#   bash common/harness-tests/next-role.sh          # 케이스 전부
#   bash common/harness-tests/next-role.sh table    # 상황별 역할을 표로 뽑는다
#
# 두 번째 꼴은 전이 규칙을 고치기 전에 쓴다. 규칙을 하나 더하거나 순서를 바꾸기 전에
# 지금 어떤 상황이 어떤 역할로 떨어지는지 한 번에 본다. PR 도 모델도 필요 없다.
#
# graph.sh·loop.sh·state.sh 와 넷째다 — 모두 동작을 재지만 모델도 GitHub 도 부르지 않는다.
# 잴 수 있는 이유는 규칙이 워크플로 셸이 아니라 .github/agent/next-role.sh 에
# 값만 받는 스크립트로 나와 있기 때문이다. 거기로 되돌리면 이 검사는 죽는다.
#
# 케이스 형식 (cases/next-role/*.case): 머리말만 있고 본문은 없다.
#   # expect: done | human | loop-off | <역할 이름들>
#   # verdict: PASS | CHANGES_REQUESTED | (빈 값)
#   # rounds: <숫자>  # max-rounds: <숫자>  # has-pat: true | false
#   # step: <숫자>    # max-steps: <숫자>   # broken: 0 | 1
#   # stage-roles: <계획에서 이번에 돌릴 역할들. 리뷰 뒤 호출이면 빈 값>

set -u

cd "$(dirname "$0")/../.."

NEXT=".github/agent/next-role.sh"
CASE_DIR="common/harness-tests/cases/next-role"

[ -f "$NEXT" ] || { echo "전이 규칙 스크립트가 없어요: $NEXT"; exit 1; }

pick() { # $1=판정 $2=라운드 $3=라운드상한 $4=PAT $5=실행횟수 $6=실행상한 $7=상태읽기실패 $8=계획역할
    VERDICT="$1" ROUNDS="$2" MAX_ROUNDS="$3" HAS_PAT="$4" \
        STEP="$5" MAX_STEPS="$6" BROKEN="$7" STAGE_ROLES="${8:-}" bash "$NEXT" 2>/dev/null
}

# ── 상황별 역할을 표로 뽑는다 ───────────────────────────────────────
if [ "${1:-}" = "table" ]; then
    printf '%-20s %-8s %-9s %-6s %-8s → %s\n' 판정 라운드 실행횟수 PAT 상태읽기 역할
    for verdict in PASS CHANGES_REQUESTED "(없음)"; do
        v="$verdict"; [ "$v" = "(없음)" ] && v=""
        for rounds in 0 3; do
            for step in 1 12; do
                for pat in true false; do
                    for broken in 0 1; do
                        printf '%-20s %-8s %-9s %-6s %-8s → %s\n' \
                            "$verdict" "$rounds/3" "$step/12" "$pat" \
                            "$([ "$broken" = 1 ] && echo 실패 || echo 성공)" \
                            "$(pick "$v" "$rounds" 3 "$pat" "$step" 12 "$broken" "")"
                    done
                done
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
    got=$(pick "$(head_of verdict)" "$(head_of rounds)" "$(head_of max-rounds)" "$(head_of has-pat)" \
               "$(head_of step)" "$(head_of max-steps)" "$(head_of broken)" "$(head_of stage-roles)")

    if [ "$got" = "$expected" ]; then
        printf 'PASS  %-32s %s\n' "$name" "$got"
        PASS=$((PASS + 1))
    else
        printf 'FAIL  %-32s 기대=%s 실제=%s\n' "$name" "$expected" "${got:-응답 없음}"
        FAIL=$((FAIL + 1))
    fi
done

printf '\n%d PASS · %d FAIL\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
