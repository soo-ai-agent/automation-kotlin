#!/usr/bin/env bash
# 🔒 기능 본체 — 루프 상태의 단일 원본. 노드와 리뷰어가 이 파일로 상태를 읽고 쓴다.
#
# 왜 필요한가: 지금 루프 상태가 세 군데에 흩어져 있다 — 라운드는 PR 코멘트 개수,
# 자동 머지 여부는 이슈 라벨, 어디까지 왔는지는 브랜치 이름. 매번 파생값을 다시 계산하는
# 구조라, 상황을 보고 다음 역할을 고르는 루프를 그 위에 올릴 수 없다.
#
# 상태는 이슈·PR 코멘트 안의 숨은 블록에 있다. 왜 거기인지, 다른 자리를 왜 안 골랐는지는
# .github/automation-spec.md 5절에 적혀 있다 — 여기 옮겨 적으면 두 곳이 어긋난다.
#
# 여기에는 GitHub API 호출이 없다. 코멘트 본문을 stdin 으로 받아 값을 내고, 값을 받아
# 블록을 낸다. 그래야 하네스가 GitHub 없이 상태를 통째로 돌려 볼 수 있다
# (tests/cases.sh — 케이스는 cases/state/).
#
# 사용:
#   state.sh read              stdin(코멘트 모음) → key=value 줄들. 블록이 여럿이면 마지막 것.
#   state.sh merge k=v ...     stdin(key=value) 에 갱신을 얹어 key=value 줄들로 낸다.
#   state.sh block             stdin(key=value) → 코멘트 끝에 붙일 숨은 블록.
#
# 상태 항목:
#   round        리뷰 라운드 — 리뷰어가 올린다
#   step         노드가 지금까지 실행된 횟수 — 노드가 올린다. 루프를 언제 멈출지 정하는 근거다
#   last_role    마지막에 돈 역할
#   last_status  그 역할의 종료 코드 (0 이면 성공)
#   verdict      마지막 리뷰 판정 (PASS | CHANGES_REQUESTED)
#   broken       상태 블록이 있는데 읽을 수 없었다는 표시
#
# **`broken=1` 일 때 무엇을 할지는 여기서 정하지 않는다.** 상태는 자기가 본 것을 말할 뿐이고,
# 멈출지 계속할지는 다음 역할을 고르는 쪽이 정한다. 판단을 두 곳에 두지 않으려는 것이다.

set -u

MARK_OPEN="<!-- claude-state"
MARK_CLOSE="-->"
KEYS="round step last_role last_status verdict broken"
NUMKEYS="round step broken"   # 없거나 망가지면 0 으로 떨어지는 항목

usage() {
    # 줄 번호로 잡으면 머리말을 고칠 때마다 엉뚱한 줄이 나온다 — 내용으로 찾는다
    sed -n 's/^#   \(state\.sh .*\)$/  \1/p' "$0"
}

# ── read: 코멘트 모음에서 마지막 상태 블록을 꺼낸다 ──────────────────
# 블록이 아예 없으면 아직 한 번도 안 돈 것이다 — 기본값에 broken=0.
# 블록이 있는데 읽을 수 없으면 broken=1. 둘을 섞으면 "처음"과 "망가짐"을 구분할 수 없다.
read_state() {
    awk -v openmark="$MARK_OPEN" -v endmark="$MARK_CLOSE" -v keys="$KEYS" '
        BEGIN {
            split(keys, k, " ")
            for (i in k) known[k[i]] = 1
        }
        index($0, openmark) == 1 { inb = 1; body = ""; seen = 1; next }
        inb && index($0, endmark) == 1 { inb = 0; last = body; next }
        inb { body = body $0 "\n" }
        END {
            if (!seen) { print "none"; exit }
            if (inb) { print "broken"; exit }   # 열리고 안 닫힘
            # 다 읽어 본 뒤에 한 번에 낸다 — 도중에 내보내면 뒤에서 망가진 것을 발견해도
            # 앞부분이 이미 나가 있어, 부르는 쪽이 "망가짐"을 정상 상태로 받는다
            n = split(last, lines, "\n")
            out = ""
            for (i = 1; i <= n; i++) {
                line = lines[i]
                if (line == "") continue
                p = index(line, "=")
                if (p < 2) { print "broken"; exit }
                key = substr(line, 1, p - 1)
                if (!(key in known)) { print "broken"; exit }
                out = out line "\n"
            }
            printf "%s", out
        }
    '
}

# ── merge: 기존 상태에 갱신을 얹는다 ─────────────────────────────────
# 항목 순서를 고정해서 낸다 — 순서가 흔들리면 같은 상태가 다른 블록이 되어 대조할 수 없다.
merge_state() { # $@=k=v 갱신
    awk -v keys="$KEYS" -v nums="$NUMKEYS" -v updates="$*" '
        BEGIN {
            count = split(keys, order, " ")
            for (i in order) known[order[i]] = 1
            split(nums, nk, " ")
            for (i in nk) numeric[nk[i]] = 1
            n = split(updates, u, " ")
            for (i = 1; i <= n; i++) {
                if (u[i] == "") continue
                p = index(u[i], "=")
                if (p < 2) { print "state: 갱신은 k=v 꼴이어야 해요: " u[i] > "/dev/stderr"; exit 2 }
                key = substr(u[i], 1, p - 1)
                if (!(key in known)) { print "state: 모르는 항목: " key > "/dev/stderr"; exit 2 }
                val[key] = substr(u[i], p + 1)
                set[key] = 1
            }
        }
        {
            p = index($0, "=")
            if (p < 2) next
            key = substr($0, 1, p - 1)
            if (!(key in set) && (key in known)) val[key] = substr($0, p + 1)
        }
        END {
            for (i = 1; i <= count; i++) {
                key = order[i]
                printf "%s=%s\n", key, (key in val ? val[key] : (key in numeric ? "0" : ""))
            }
        }
    '
}

# 숫자여야 하는 항목에 숫자가 아닌 것이 들어 있으면 읽기에 실패한 것으로 본다.
# 그 값은 0 으로 되돌리고 broken=1 을 세운다 — broken 을 안 보는 호출자도 숫자는 받게.
check_numbers() { # stdin=key=value → 같은 것을 내보내되, 이상하면 0 으로 되돌리고 broken=1
    awk -v nums="$NUMKEYS" '
        BEGIN { split(nums, nk, " "); for (i in nk) numeric[nk[i]] = 1 }
        {
            p = index($0, "=")
            key[NR] = substr($0, 1, p - 1)
            val[NR] = substr($0, p + 1)
            if ((key[NR] in numeric) && val[NR] !~ /^[0-9]+$/) { val[NR] = 0; bad = 1 }
        }
        END {
            for (i = 1; i <= NR; i++) {
                if (key[i] == "broken") printf "broken=%s\n", (bad || val[i] == "1" ? 1 : 0)
                else printf "%s=%s\n", key[i], val[i]
            }
        }
    '
}

case "${1:-}" in
    read)
        raw=$(read_state)
        # 빠진 항목은 merge_state 가 기본값으로 채운다 — 기본값을 아는 곳을 하나로 둔다
        case "$raw" in
            none) printf '' | merge_state ;;
            broken) printf '' | merge_state broken=1 ;;
            *) printf '%s\n' "$raw" | merge_state | check_numbers ;;
        esac
        ;;
    merge)
        shift
        merge_state "$@"
        ;;
    block)
        printf '%s\n' "$MARK_OPEN"
        cat
        printf '%s\n' "$MARK_CLOSE"
        ;;
    -h | --help | help | '')
        usage
        ;;
    *)
        echo "state: 모르는 명령: $1" >&2
        usage >&2
        exit 2
        ;;
esac
