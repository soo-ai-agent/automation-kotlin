#!/usr/bin/env bash
# 그래프 회귀 — CLAUDE_GRAPH 표현식이 의도한 단계 매트릭스로 펼쳐지는지 본다.
#
# 사용 (저장소 루트에서):
#   bash common/harness-tests/graph.sh                  # 케이스 전부
#   bash common/harness-tests/graph.sh 'api+web>e2e'    # 이 표현식 한 번 펼쳐 보기
#
# 두 번째 꼴은 그래프를 고치기 전에 결과를 미리 보는 데 쓴다. 워크플로를 돌리지 않아도 된다.
#
# static.sh·run.sh 와 나눈 이유:
#   static.sh 는 "규칙이 읽히기는 하는가"(링크·경로·형식)를 보고,
#   run.sh 는 "규칙이 옳은가"를 모델에게 묻는다(케이스당 claude 호출 1건).
#   여기는 그 사이다 — **동작을 재지만 모델을 부르지 않는다.** graph.js 가
#   환경변수를 받아 JSON 을 뱉는 순수한 도구라서 그대로 돌려 대조할 수 있다.
#
# 케이스 형식 (cases/graph/*.case):
#   # expect: PASS | FAIL      PASS 면 stdout 이 본문과 같아야 하고, FAIL 이면 0 아닌 종료에
#   # graph: <표현식>          CLAUDE_GRAPH 로 넘길 값
#   # node: <이름>             (선택) CLAUDE_NODE — 그래프를 무시하고 이 노드 하나만
#   <본문>                     PASS 면 기대 stdout 전문, FAIL 이면 stderr 에 있어야 할 한 줄

set -u

cd "$(dirname "$0")/../.."

GRAPH_JS=".github/agent/graph.js"
CASE_DIR="common/harness-tests/cases/graph"

[ -f "$GRAPH_JS" ] || { echo "그래프 도구가 없어요: $GRAPH_JS"; exit 1; }
command -v node >/dev/null || { echo "node 가 필요해요"; exit 1; }

# GITHUB_OUTPUT 이 있으면 graph.js 가 stdout 대신 그 파일에 쓴다 — CI 에서 빈 출력이 된다.
# 여기서는 언제나 stdout 으로 받아야 하므로 그 변수를 지우고 부른다.
expand() { # $1=그래프 표현식, $2=단일 노드 → stdout 에 stages=, stderr 는 호출자가 받는다
    env -u GITHUB_OUTPUT CLAUDE_GRAPH="$1" CLAUDE_NODE="$2" node "$GRAPH_JS"
}

# ── 표현식 하나를 펼쳐 보여 준다 ────────────────────────────────────
if [ "$#" -gt 0 ]; then
    case "$1" in
        -h | --help | help)
            # 머리말 주석을 그대로 보여 준다 — 줄 번호를 박으면 머리말이 바뀔 때 어긋난다
            awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
            exit 0
            ;;
    esac
    expand "$1" ""
    exit $?
fi

PASS=0
FAIL=0

for case_file in "$CASE_DIR"/*.case; do
    [ -e "$case_file" ] || continue
    name=$(basename "$case_file" .case)

    expected=$(sed -n 's/^# expect: //p' "$case_file" | head -n 1)
    graph=$(sed -n 's/^# graph: //p' "$case_file" | head -n 1)
    single=$(sed -n 's/^# node: //p' "$case_file" | head -n 1)
    # 본문은 머리말(#)과 빈 줄을 뺀 나머지다
    body=$(grep -v '^#' "$case_file" | grep -v '^[[:space:]]*$')

    out=$(expand "$graph" "$single" 2>/tmp/graph-err.txt)
    status=$?

    if [ "$expected" = "PASS" ]; then
        if [ "$status" -eq 0 ] && [ "$out" = "$body" ]; then
            printf 'PASS  %-24s %s\n' "$name" "$graph"
            PASS=$((PASS + 1))
        else
            printf 'FAIL  %-24s %s\n' "$name" "$graph"
            [ "$status" -eq 0 ] || printf '     └ 종료코드 %s: %s\n' "$status" "$(head -n 1 /tmp/graph-err.txt)"
            [ "$out" = "$body" ] || diff <(printf '%s\n' "$body") <(printf '%s\n' "$out") | sed 's/^/     │ /'
            FAIL=$((FAIL + 1))
        fi
    else
        # 실패 기대 — 0 아닌 종료로 끝나고, 본문의 한 줄이 stderr 에 있어야 한다.
        # 종료코드만 보면 "아무 이유로나 죽는 것"까지 통과시킨다.
        if [ "$status" -ne 0 ] && grep -qF "$body" /tmp/graph-err.txt; then
            printf 'PASS  %-24s %s (막힘)\n' "$name" "$graph"
            PASS=$((PASS + 1))
        else
            printf 'FAIL  %-24s %s\n' "$name" "$graph"
            printf '     └ 종료코드 %s, 기대한 메시지 없음: %s\n' "$status" "$body"
            FAIL=$((FAIL + 1))
        fi
    fi
done

printf '\n%d PASS · %d FAIL\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
