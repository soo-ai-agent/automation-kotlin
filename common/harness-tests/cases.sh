#!/usr/bin/env bash
# 케이스 러너 — cases/ 아래의 모든 케이스를 돌린다. 모델도 GitHub 도 부르지 않는다.
#
# 사용 (저장소 루트에서):
#   bash common/harness-tests/cases.sh            # 전부
#   bash common/harness-tests/cases.sh next-role  # 그 폴더만
#
# 케이스가 스스로 무엇을 돌릴지 적는다. 그래서 러너는 종류마다 다르지 않고 이것 하나다.
#
#   # 설명 (아무 줄이나)
#   # run: <명령>              무엇을 돌리나
#   # expect: <기대 stdout>    한 줄로 대조한다
#   # expect-stderr: <문구>    (선택) 이것이 있으면 0 아닌 종료 + stderr 에 이 문구
#   # <키>: <값>               나머지 머리말은 환경변수가 된다 (max-steps → MAX_STEPS)
#   ---                        (선택) 이 줄 아래는 명령의 stdin 으로 들어간다
#
# 나온 값은 줄바꿈을 공백으로 바꿔 한 줄로 대조한다 — 기대값을 한 줄로 적을 수 있게.
#
# 계획처럼 여러 바퀴를 이어 돌려야 하는 것은 `# run: walk` 로 적는다. 아래 walk() 가
# claude-agent.yml 의 next 잡과 같은 계산(stage+1, step+역할수)으로 끝까지 돈다.

set -u

cd "$(dirname "$0")/../.."

CASE_ROOT="common/harness-tests/cases"

# 계획을 끝까지 돌려 바퀴마다의 역할을 ' | ' 로 이어 낸다.
walk() {
    stage=0
    step=0
    turn=0
    trace=""
    while [ "$turn" -lt 20 ]; do
        turn=$((turn + 1))
        out=$(STAGE="$stage" STEP="$step" bash .github/agent/plan-stage.sh 2>/dev/null)
        roles=$(printf '%s\n' "$out" | sed -n 's/^roles=//p')
        [ -z "$trace" ] && trace="$roles" || trace="$trace | $roles"
        [ "$(printf '%s\n' "$out" | sed -n 's/^has_next=//p')" = "true" ] || break
        stage=$((stage + 1))
        step=$((step + $(printf '%s' "$roles" | wc -w)))
    done
    printf '%s' "$trace"
}

# 머리말의 `# 키: 값` 을 환경변수로 바꿔 export 한다. 하이픈은 밑줄로, 이름은 대문자로.
export_headers() { # $1=케이스 파일
    while IFS= read -r line; do
        key=${line%%:*}
        key=${key#\# }
        case "$key" in
            run | expect | expect-stderr | "$line") continue ;;
        esac
        value=${line#*: }
        [ "$value" = "$line" ] && value=""
        # shellcheck disable=SC2163
        export "$(printf '%s' "$key" | tr 'a-z-' 'A-Z_')=$value"
    done < <(sed '/^---$/,$d' "$1" | grep -E '^# [a-z][a-z-]*:')
}

run_case() { # $1=케이스 파일 → PASS 면 0
    field() { sed -n "s/^# $1: \{0,1\}//p" "$2" | head -n 1; }
    cmd=$(field run "$1")
    want=$(field expect "$1")
    want_err=$(field expect-stderr "$1")
    # --- 아래가 stdin 이다. 본문에 `#` 로 시작하는 줄이 있어도 머리말과 안 섞인다.
    body=$(sed -n '/^---$/,$p' "$1" | tail -n +2)

    (
        export_headers "$1"
        if [ "$cmd" = "walk" ]; then
            walk
        else
            printf '%s' "$body" | eval "$cmd"
        fi
    ) > /tmp/case-out.txt 2> /tmp/case-err.txt
    status=$?

    if [ -n "$want_err" ]; then
        # 막혀야 하는 케이스 — 종료코드만 보면 아무 이유로 죽어도 통과한다
        [ "$status" -ne 0 ] && grep -qF "$want_err" /tmp/case-err.txt
    else
        got=$(tr '\n' ' ' < /tmp/case-out.txt)
        [ "$status" -eq 0 ] && [ "${got% }" = "$want" ]
    fi
}

PASS=0
FAIL=0
only="${1:-}"

for dir in "$CASE_ROOT"/*/; do
    family=$(basename "$dir")
    [ -z "$only" ] || [ "$only" = "$family" ] || continue
    for case_file in "$dir"*.case; do
        [ -e "$case_file" ] || continue
        name="$family/$(basename "$case_file" .case)"
        if run_case "$case_file"; then
            printf 'PASS  %-46s %s\n' "$name" "$(tr '\n' ' ' < /tmp/case-out.txt | head -c 90)"
            PASS=$((PASS + 1))
        else
            printf 'FAIL  %-46s\n' "$name"
            printf '     │ 기대 %s\n' "$(sed -n 's/^# expect\(-stderr\)\{0,1\}: //p' "$case_file" | head -n 1)"
            printf '     └ 실제 %s\n' "$(tr '\n' ' ' < /tmp/case-out.txt | head -c 200)$(head -c 120 /tmp/case-err.txt)"
            FAIL=$((FAIL + 1))
        fi
    done
done

printf '\n%d PASS · %d FAIL\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
