#!/usr/bin/env bash
# 상태 회귀 — 루프 상태를 코멘트에서 읽고, 갱신하고, 다시 쓰는 것이 맞는지 본다.
#
# 사용 (저장소 루트에서):
#   bash common/harness-tests/state.sh          # 케이스 전부
#   bash common/harness-tests/state.sh show     # 왕복 한 번을 눈으로 보기
#
# graph.sh·loop.sh 와 셋째다 — 모두 **동작을 재지만 모델도 GitHub 도 부르지 않는다.**
# 잴 수 있는 이유는 .github/agent/state.sh 가 stdin 을 받아 stdout 을 내는 순수한
# 도구이기 때문이다. GitHub API 호출이 그 안으로 들어가면 이 검사는 죽는다.
#
# 케이스 형식 (cases/state/*.case):
#   # expect: <key=value 를 공백으로 이은 한 줄>
#   # merge: <k=v ...>        (선택) 읽은 뒤 얹을 갱신
#   <본문>                    코멘트 모음. 상태 블록이 있으면 그 안에서 읽는다.

set -u

cd "$(dirname "$0")/../.."

STATE=".github/agent/state.sh"
CASE_DIR="common/harness-tests/cases/state"

[ -f "$STATE" ] || { echo "상태 스크립트가 없어요: $STATE"; exit 1; }

# ── 손잡이: 왕복 한 번을 보여 준다 ──────────────────────────────────
if [ "${1:-}" = "show" ]; then
    printf '## 리뷰 코멘트\n<!-- claude-state\nround=1\nstep=3\nlast_role=code\nlast_status=0\nverdict=CHANGES_REQUESTED\nbroken=0\n-->\n' > /tmp/state-show.txt
    echo "── 코멘트에서 읽은 상태"
    bash "$STATE" read < /tmp/state-show.txt | sed 's/^/   /'
    echo "── round 을 올리고 역할을 바꾼 뒤 다시 쓴 블록"
    bash "$STATE" read < /tmp/state-show.txt \
        | bash "$STATE" merge round=2 last_role=fix \
        | bash "$STATE" block | sed 's/^/   /'
    exit 0
fi

PASS=0
FAIL=0

for case_file in "$CASE_DIR"/*.case; do
    [ -e "$case_file" ] || continue
    name=$(basename "$case_file" .case)

    expected=$(sed -n 's/^# expect: //p' "$case_file" | head -n 1)
    updates=$(sed -n 's/^# merge: //p' "$case_file" | head -n 1)

    # 본문은 머리말(#)을 뺀 나머지 — 상태 블록의 '#' 없는 줄만 남는다
    body=$(grep -v '^# ' "$case_file")

    if [ -n "$updates" ]; then
        # shellcheck disable=SC2086
        got=$(printf '%s\n' "$body" | bash "$STATE" read | bash "$STATE" merge $updates | tr '\n' ' ')
    else
        got=$(printf '%s\n' "$body" | bash "$STATE" read | tr '\n' ' ')
    fi
    got=${got% }

    if [ "$got" = "$expected" ]; then
        printf 'PASS  %-28s %s\n' "$name" "$got"
        PASS=$((PASS + 1))
    else
        printf 'FAIL  %-28s\n     │ 기대 %s\n     └ 실제 %s\n' "$name" "$expected" "${got:-응답 없음}"
        FAIL=$((FAIL + 1))
    fi
done

printf '\n%d PASS · %d FAIL\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
