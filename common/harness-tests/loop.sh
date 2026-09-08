#!/usr/bin/env bash
# 루프 회귀 — 리뷰 루프가 상황마다 무엇을 하기로 하는지 본다.
#
# 사용 (저장소 루트에서):
#   bash common/harness-tests/loop.sh          # 케이스 전부
#   bash common/harness-tests/loop.sh table    # 상황별 결정을 표로 뽑아 보기
#
# 두 번째 꼴이 루프를 설계할 때 쓰는 손잡이다. 상한을 바꾸거나 조건을 더하기 전에
# 지금 어떤 상황이 어떤 결정으로 떨어지는지 한눈에 본다. PR 도 모델도 필요 없다.
#
# graph.sh 와 짝이다 — 둘 다 **동작을 재지만 모델을 부르지 않는다.**
# 잴 수 있는 이유는 판단이 워크플로 셸이 아니라 .github/agent/loop-decision.sh 에
# 값만 받는 스크립트로 나와 있기 때문이다. 거기로 되돌리면 이 검사는 죽는다.
#
# 케이스 형식 (cases/loop/*.case): 머리말만 있고 본문은 없다.
#   # expect: merge | human-merge | fix | human-stop | loop-off
#   # verdict: PASS | CHANGES_REQUESTED
#   # head-ref: <브랜치 이름>
#   # agent-made: true | false | unknown
#   # rounds: <숫자>   # max-rounds: <숫자>   # has-pat: true | false

set -u

cd "$(dirname "$0")/../.."

DECIDE=".github/agent/loop-decision.sh"
CASE_DIR="common/harness-tests/cases/loop"

[ -f "$DECIDE" ] || { echo "루프 판단 스크립트가 없어요: $DECIDE"; exit 1; }

decide() { # $1=판정 $2=브랜치 $3=라벨 $4=라운드 $5=상한 $6=PAT
    VERDICT="$1" HEAD_REF="$2" AGENT_MADE="$3" ROUNDS="$4" MAX_ROUNDS="$5" HAS_PAT="$6" \
        bash "$DECIDE"
}

# ── 손잡이: 상황별 결정을 표로 ───────────────────────────────────────
if [ "${1:-}" = "table" ]; then
    printf '%-18s %-22s %-11s %-7s %-7s → %s\n' 판정 브랜치 claude-made 라운드 PAT 결정
    for verdict in PASS CHANGES_REQUESTED; do
        for ref in claude/issue-42 feat/hand-written; do
            for made in true false unknown; do
                for rounds in 0 3; do
                    for pat in true false; do
                        printf '%-18s %-22s %-11s %-7s %-7s → %s\n' \
                            "$verdict" "$ref" "$made" "$rounds/3" "$pat" \
                            "$(decide "$verdict" "$ref" "$made" "$rounds" 3 "$pat")"
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
    got=$(decide "$(head_of verdict)" "$(head_of head-ref)" "$(head_of agent-made)" \
                 "$(head_of rounds)" "$(head_of max-rounds)" "$(head_of has-pat)")

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
