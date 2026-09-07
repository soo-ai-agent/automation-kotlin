#!/usr/bin/env bash
# 루프 회귀 — 리뷰어의 지적을 작성자가 고치면 통과로 수렴하는지 본다.
#
# 사용 (저장소 루트에서):
#   bash common/harness-tests/loop.sh                    # 전부, 최대 2라운드
#   bash common/harness-tests/loop.sh backend            # 백엔드 케이스만
#   bash common/harness-tests/loop.sh all --rounds 3     # 라운드 수 지정
#   bash common/harness-tests/loop.sh all --rounds 3 --yes   # 호출 30건 이상 승인
#
# run.sh 와 무엇이 다른가:
#   run.sh   판정 한 번. "잡아야 할 것을 잡는가"만 본다.
#   loop.sh  판정 → 수정 → 재판정을 반복한다. "지적을 따라 고치면 통과에 닿는가"를 본다.
#
# 왜 필요한가: 리뷰어가 위반을 잡아도, 지적이 무엇을 어떻게 고치라는 것인지 알 수 없으면
# 작성자는 통과에 닿지 못한다. 규칙끼리 서로 어긋나 있어도 마찬가지다. 그 상태는 판정
# 한 번만 보는 run.sh 로는 드러나지 않는다.
#
# 리뷰어와 작성자는 **각각 다른 claude 세션**이다. 한 세션이 자기가 쓴 코드를 자기가
# 심사하면 통과 판정이 쉬워져 검사가 되지 않는다. 역할 지시문도 각자 다른 파일에서 온다.
#   리뷰어 .github/agent/review-role.md   — 실제 PR 리뷰어와 같은 파일
#   작성자 .github/agent/nodes/fix.md     — 실제 fix 노드와 같은 파일
#
# 대상 케이스: '# expect: CHANGES_REQUESTED' 인 것만. 통과 기대 케이스는 고칠 것이 없다.
#
# 준비물: claude CLI 로그인 (`claude setup-token`)
#
# ⚠️ 비용이 크다. 케이스 하나에 claude 호출이 최대 (1 + 라운드수 x 2) 건이다.
#    30건을 넘기면 --yes 없이는 돌지 않는다 (CLAUDE.md 의 대량 호출 승인 규칙).

set -u

cd "$(dirname "$0")/../.."

REVIEWER_ROLE=".github/agent/review-role.md"
AUTHOR_ROLE=".github/agent/nodes/fix.md"
SETTINGS_FILE=".github/agent/settings.env"

# 호출 승인 문턱 — CLAUDE.md 가 정한 값이다
APPROVAL_THRESHOLD=30

usage() {
    cat << USAGE
사용법: bash common/harness-tests/loop.sh [backend|frontend|all] [--rounds N] [--yes]

  backend      common/harness-tests/cases/backend/ 의 차단 기대 케이스
  frontend     common/harness-tests/cases/frontend/ 의 차단 기대 케이스
  all          둘 다 (기본값)

  --rounds N   작성자가 고쳐 볼 최대 횟수 (기본 2)
  --yes        예상 호출이 ${APPROVAL_THRESHOLD}건 이상이어도 진행

판정 한 번만 보는 것은 run.sh 다. 이 스크립트는 지적을 따라 고쳤을 때
통과로 수렴하는지를 본다.
USAGE
}

AREA="all"
ROUNDS=2
APPROVED="no"

while [ $# -gt 0 ]; do
    case "$1" in
        backend | be) AREA="backend"; shift ;;
        frontend | fe) AREA="frontend"; shift ;;
        all) AREA="all"; shift ;;
        --rounds)
            shift
            ROUNDS="${1:-}"
            case "$ROUNDS" in
                ''|*[!0-9]*) echo "--rounds 는 숫자여야 해요" >&2; exit 2 ;;
            esac
            [ "$ROUNDS" -ge 1 ] || { echo "--rounds 는 1 이상이어야 해요" >&2; exit 2; }
            shift
            ;;
        --yes) APPROVED="yes"; shift ;;
        -h | --help | help) usage; exit 0 ;;
        *) echo "모르는 인자: $1" >&2; echo >&2; usage >&2; exit 2 ;;
    esac
done

case "$AREA" in
    backend) CASE_DIRS="common/harness-tests/cases/backend" ;;
    frontend) CASE_DIRS="common/harness-tests/cases/frontend" ;;
    all) CASE_DIRS="common/harness-tests/cases/backend common/harness-tests/cases/frontend" ;;
esac

command -v claude >/dev/null || { echo "claude CLI 가 필요해요: claude setup-token"; exit 1; }
for f in "$REVIEWER_ROLE" "$AUTHOR_ROLE"; do
    [ -f "$f" ] || { echo "역할 지시문이 없어요: $f"; exit 1; }
done

# 통과 기준과 규칙 위치는 워크플로와 같은 곳에서 읽는다 — 여기 베껴 적으면 둘이 어긋난다.
# shellcheck source=/dev/null
. "$SETTINGS_FILE"

# 차단 기대 케이스만 모은다. 통과 기대 케이스는 작성자가 고칠 것이 없다.
TARGETS=""
for case_dir in $CASE_DIRS; do
    for case_file in "$case_dir"/*.diff; do
        [ -e "$case_file" ] || continue
        head -n 1 "$case_file" | grep -qx '# expect: CHANGES_REQUESTED' && TARGETS="$TARGETS $case_file"
    done
done

CASE_COUNT=$(printf '%s\n' $TARGETS | grep -c . || true)
[ "$CASE_COUNT" -gt 0 ] || { echo "돌릴 차단 기대 케이스가 없어요 ($AREA)"; exit 1; }

# 최악의 경우 호출 수 — 첫 판정 1건 + 라운드마다 (수정 1건 + 재판정 1건)
MAX_CALLS=$(( CASE_COUNT * (1 + ROUNDS * 2) ))

echo "▶ 루프 회귀 — $AREA · 케이스 ${CASE_COUNT}건 · 최대 ${ROUNDS}라운드"
echo "  예상 claude 호출: 최대 ${MAX_CALLS}건 (수렴하면 줄어든다)"

if [ "$MAX_CALLS" -ge "$APPROVAL_THRESHOLD" ] && [ "$APPROVED" != "yes" ]; then
    echo
    echo "호출이 ${APPROVAL_THRESHOLD}건 이상이라 멈췄어요. CLAUDE.md 가 대량 호출은 시작 전에" >&2
    echo "승인을 받으라고 정합니다. 그대로 돌리려면 --yes 를, 줄이려면 --rounds 나 영역을 쓰세요." >&2
    exit 3
fi

# 리뷰어와 작성자가 함께 받는 입력. claude-review.yml 의 '리뷰' 스텝과 같은 구조다.
# $1 = 이번에 판단할 diff 파일, $2 = 리뷰 지적 파일(작성자에게만, 없으면 빈 문자열)
build_input() {
    printf '## 리뷰 규칙\n\n'
    find "$CLAUDE_REVIEW_RULES_DIR" -name '*.md' -type f -print0 2>/dev/null | sort -z | xargs -0 -r cat
    printf '\n\n## 통과 기준\n\n%s\n' "$CLAUDE_REVIEW_BAR"
    if [ -n "$2" ]; then
        printf '\n\n## 리뷰 지적\n\n'
        cat "$2"
    fi
    printf '\n\n## DIFF\n\n'
    cat "$1"
}

# --add-dir 은 하위 폴더의 스킬을 세션 스킬 목록에 올린다. 리뷰어도 작성자도
# 영역 스킬(kotlin-*, frontend-*)을 보고 판단해야 하므로 양쪽 다 붙인다.
#
# --disallowedTools 로 파일 수정과 셸을 막는다. 이 하네스에서 두 세션이 내놓을 것은
# 판정문과 diff 텍스트뿐인데, 저장소 루트에서 돌기 때문에 지시문만으로 막으면
# 작성자가 실제 파일을 고칠 수 있다.
#
# 출력은 파일로 받는다. grep 으로 바로 파이프하면 파이프가 먼저 닫혀 claude 가 죽는다.
run_agent() { # $1=역할 프롬프트 파일, $2=입력 파일, $3=출력 파일
    claude --add-dir backend --add-dir frontend \
        --disallowedTools "Write,Edit,NotebookEdit,Bash" \
        --output-format text -p "$(cat "$1")" \
        < "$2" > "$3" 2> /tmp/loop-error.txt
}

# 작성자에게는 역할 지시문에 하네스 입출력 규약을 덧붙인다.
# 실제 fix 노드는 저장소 파일을 고치고 빌드를 돌리지만, 하네스에는 그 파일이 없다.
# 역할 자체를 바꾸는 것이 아니라 결과를 받는 방식만 정하는 것이다.
AUTHOR_PROMPT="/tmp/loop-author-role.txt"
{
    cat "$AUTHOR_ROLE"
    printf '\n\n## 이 하네스의 입출력 규약\n\n'
    printf '저장소에 실제 파일이 없다. 빌드·테스트 명령을 돌리지 말고, 파일도 고치지 마라.\n'
    printf "입력 'DIFF' 절을 '리뷰 지적' 절대로 고친 **새 diff 만** 출력한다.\n"
    printf '설명·머리말·코드펜스를 붙이지 말고 diff 본문으로 시작한다.\n'
} > "$AUTHOR_PROMPT"

PASS=0
FAIL=0
CALLS=0

for case_file in $TARGETS; do
    name=$(basename "$case_file" .diff)
    work="/tmp/loop-diff.txt"
    tail -n +2 "$case_file" > "$work"

    verdict=""
    result=""
    used_rounds=0

    # 첫 판정 — 여기서 통과가 나오면 케이스가 위반을 못 심었거나 리뷰어가 놓친 것이다
    build_input "$work" "" > /tmp/loop-input.txt
    run_agent "$REVIEWER_ROLE" /tmp/loop-input.txt /tmp/loop-review.txt
    CALLS=$((CALLS + 1))
    verdict=$(grep -m1 "VERDICT:" /tmp/loop-review.txt)

    if [ -z "$verdict" ]; then
        result="첫 판정에서 응답 없음"
    elif printf '%s' "$verdict" | grep -q "PASS"; then
        result="첫 판정이 통과 — 위반이 안 심겼거나 리뷰어가 놓쳤다"
    fi

    round=0
    while [ -z "$result" ] && [ "$round" -lt "$ROUNDS" ]; do
        round=$((round + 1))

        # 작성자 — 지적을 보고 고친 diff 를 내놓는다
        build_input "$work" /tmp/loop-review.txt > /tmp/loop-input.txt
        run_agent "$AUTHOR_PROMPT" /tmp/loop-input.txt /tmp/loop-author.txt
        CALLS=$((CALLS + 1))

        # 설명이 앞에 붙어 나와도 diff 본문부터만 남긴다
        awk '/^(diff --git|--- )/ { seen = 1 } seen' /tmp/loop-author.txt > /tmp/loop-next.txt
        if [ ! -s /tmp/loop-next.txt ]; then
            result="${round}라운드 — 작성자가 diff 를 내놓지 못했다"
            break
        fi
        cp /tmp/loop-next.txt "$work"

        # 리뷰어 — 고쳐진 diff 를 다시 판정한다
        build_input "$work" "" > /tmp/loop-input.txt
        run_agent "$REVIEWER_ROLE" /tmp/loop-input.txt /tmp/loop-review.txt
        CALLS=$((CALLS + 1))
        verdict=$(grep -m1 "VERDICT:" /tmp/loop-review.txt)

        if [ -z "$verdict" ]; then
            result="${round}라운드 재판정에서 응답 없음"
        elif printf '%s' "$verdict" | grep -q "PASS"; then
            used_rounds="$round"
        fi
        [ "$used_rounds" -gt 0 ] && break
    done

    if [ -z "$result" ] && [ "$used_rounds" -gt 0 ]; then
        printf 'PASS  %-28s %d라운드에 수렴\n' "$name" "$used_rounds"
        PASS=$((PASS + 1))
    else
        [ -n "$result" ] || result="${ROUNDS}라운드 안에 통과에 닿지 못했다"
        printf 'FAIL  %-28s %s\n' "$name" "$result"
        FAIL=$((FAIL + 1))
    fi
done

printf '\n%d PASS · %d FAIL · claude 호출 %d건\n' "$PASS" "$FAIL" "$CALLS"
[ "$FAIL" -eq 0 ]
