#!/usr/bin/env bash
# 디스패처 판단 회귀 — 이슈를 착수시킬지, 그리고 끝난 것을 치울지 본다.
#
# 사용 (저장소 루트에서):
#   bash common/harness-tests/dispatch.sh          # 케이스 전부
#   bash common/harness-tests/dispatch.sh table    # 상황별 결정을 표로 뽑는다
#
# 다른 갈래와 같은 모양이다 — 판단이 .github/agent/dispatch_rules.py 에 값만 받는
# 함수로 나와 있어서 GitHub 없이 돌려 볼 수 있다. 거기로 되돌리면 이 검사는 죽는다.
#
# 여기서 재는 것은 **사람이 만든 것을 지우지 않는지**다. 이슈를 닫고 PR 을 닫고
# 브랜치를 지우는 판단이라, 틀리면 되돌릴 수 없다. 그래서 "판별 불가" 케이스가 많다.
#
# 케이스 형식 (cases/dispatch/*.case): 머리말만 있고 본문은 없다.
#   # expect: <한 단어>
#   # decision: start | close-issue | close-pr | delete-branch
#   # 그 판단이 쓰는 값만 적는다:
#   #   start          has-pat · labels
#   #   close-issue    labels · pr-open · pr-merged
#   #   close-pr       head-ref · issue-state
#   #   delete-branch  branch · pr-open · ahead-by

set -u

cd "$(dirname "$0")/../.."

RULES=".github/agent/dispatch_rules.py"
CASE_DIR="common/harness-tests/cases/dispatch"

[ -f "$RULES" ] || { echo "판단 규칙이 없어요: $RULES"; exit 1; }

ask() { # $1=판단 이름, 나머지는 환경변수로 미리 깔아 둔다
    python3 "$RULES" "$1"
}

# ── 상황별 결정을 표로 뽑는다 ───────────────────────────────────────
if [ "${1:-}" = "table" ]; then
    printf '%-14s %-34s → %s\n' 판단 상황 결정
    for labels in "claude" "claude claude-sent" "claude claude-split" "claude-split claude-sent"; do
        printf '%-14s %-34s → %s\n' start "라벨: $labels" \
            "$(HAS_PAT=true LABELS="$labels" ask start)"
    done
    printf '%-14s %-34s → %s\n' start "PAT 없음" "$(HAS_PAT=false LABELS="claude" ask start)"
    for state in closed open unknown; do
        printf '%-14s %-34s → %s\n' close-pr "이슈가 $state" \
            "$(HEAD_REF=claude/issue-42 ISSUE_STATE="$state" ask close-pr)"
    done
    for ahead in 0 3 ""; do
        printf '%-14s %-34s → %s\n' delete-branch "앞선 커밋 ${ahead:-조회실패}" \
            "$(BRANCH=claude/issue-42 PR_OPEN=false AHEAD_BY="$ahead" ask delete-branch)"
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
    got=$(HAS_PAT="$(head_of has-pat)" LABELS="$(head_of labels)" \
          PR_OPEN="$(head_of pr-open)" PR_MERGED="$(head_of pr-merged)" \
          HEAD_REF="$(head_of head-ref)" ISSUE_STATE="$(head_of issue-state)" \
          BRANCH="$(head_of branch)" AHEAD_BY="$(head_of ahead-by)" \
          ask "$(head_of decision)")

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
