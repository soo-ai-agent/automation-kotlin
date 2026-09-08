#!/usr/bin/env bash
# 🔒 기능 본체 — 리뷰가 끝난 뒤 다음에 어느 역할을 부를지 정하는 곳.
#
# **아직 아무도 부르지 않는다.** 리뷰어는 여전히 `fix` 를 이름으로 박아 부른다.
# 부르는 쪽을 옮기는 것은 다음 단계다 (common/docs/automation-spec.md 5절).
#
# 여기에는 GitHub API 호출도 파일 쓰기도 없다. 값을 받아 한 단어를 stdout 에 낸다.
# 그래야 하네스가 모델도 GitHub 도 없이 전이 규칙을 통째로 돌려 볼 수 있다
# (common/harness-tests/next-role.sh — 케이스는 cases/next-role/).
#
# 받는 값 (환경변수):
#   VERDICT    PASS | CHANGES_REQUESTED   마지막 리뷰 판정. 리뷰 전이면 빈 값
#   STEP       지금까지 노드가 실행된 횟수 (state.sh 의 step)
#   MAX_STEPS  그 상한 (settings.env 의 CLAUDE_MAX_STEPS)
#   BROKEN     상태를 읽지 못했다는 표시 (state.sh 의 broken)
#
# 내는 값 (stdout 한 단어):
#   done       더 부를 역할이 없다. 루프를 끝낸다
#   human      자동으로 이어갈 수 없다. 사람을 부른다
#   <역할 이름>  .github/agent/nodes/<이름>.md 가 있는 역할
#
# 규칙은 위에서 아래로 읽는다. **먼저 걸리는 것이 이긴다.**
# 멈추는 조건을 앞에 둔 것은 일부러다 — 판별이 안 될 때 계속 도는 쪽이 아니라
# 멈추는 쪽으로 떨어져야 한다. 오늘은 이 둘이 없어서, 상태를 못 읽어도 몇 번을 돌았어도
# 계속 fix 를 불렀다.

set -u

VERDICT="${VERDICT:-}"
STEP="${STEP:-0}"
MAX_STEPS="${MAX_STEPS:-0}"
BROKEN="${BROKEN:-0}"

# ① 상태를 못 읽었다. 몇 번 돌았는지도 무엇을 했는지도 모르는 채로 이어가지 않는다.
if [ "$BROKEN" = "1" ]; then
    echo "human"
    exit 0
fi

# ② 실행 횟수를 숫자로 읽을 수 없다. ① 과 같은 갈래다 — 받은 값을 못 믿는다.
case "$STEP$MAX_STEPS" in
    '' | *[!0-9]*) echo "human"; exit 0 ;;
esac

# ③ 통과했다. 더 부를 역할이 없다.
#
#    **상한 검사(④)보다 앞에 둔다.** 상한은 일을 더 시키지 않으려는 것이고,
#    통과는 시킬 일이 없다는 뜻이라 상한에 걸릴 이유가 없다. 순서를 뒤집으면
#    상한에 닿은 순간 통과한 PR 까지 사람을 부르며 막힌다.
#
#    머지할지 사람이 할지는 loop-decision.sh 가 따로 정한다 —
#    여기서는 "더 부를 역할이 없다"까지만 말한다.
if [ "$VERDICT" = "PASS" ]; then
    echo "done"
    exit 0
fi

# ④ 너무 많이 돌았다. 리뷰 라운드 상한(CLAUDE_MAX_ROUNDS)과는 다른 상한이다 —
#    저쪽은 같은 PR 을 몇 번 다시 보는지이고, 이쪽은 노드가 통틀어 몇 번 실행됐는지다.
if [ "$STEP" -ge "$MAX_STEPS" ]; then
    echo "human"
    exit 0
fi

# ⑤ 지적이 남았다. 고치는 역할은 fix 하나다.
#
#    영역별로 나누고 싶을 수 있다(백엔드 지적이면 백엔드만 고치는 역할). 지금은 안 한다 —
#    api·web 노드의 지시문은 "기능을 구현한다"이지 "지적을 고친다"가 아니라서,
#    지적을 그쪽에 넘기면 시키는 일과 역할이 어긋난다. 나누려면 그런 역할 파일이 먼저 있어야 한다.
if [ "$VERDICT" = "CHANGES_REQUESTED" ]; then
    echo "fix"
    exit 0
fi

# ⑥ 판정이 없거나 모르는 값이다. 리뷰가 돌지 않았거나 형식이 바뀐 것이라 사람이 봐야 한다.
echo "human"
