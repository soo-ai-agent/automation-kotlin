#!/usr/bin/env bash
# 🔒 기능 본체 — 리뷰가 끝난 뒤 다음에 어느 역할을 부를지 정하는 곳.
#
# 머지할지는 loop-decision.sh 가 따로 정한다. 여기는 **다음에 무엇을 돌릴지**만 정한다 —
# "계속할까"를 두 곳에서 재면 상한 하나를 바꿀 때 두 군데를 고쳐야 한다.
#
# 여기에는 GitHub API 호출도 파일 쓰기도 없다. 값을 받아 한 단어를 stdout 에 낸다.
# 그래야 하네스가 모델도 GitHub 도 없이 전이 규칙을 통째로 돌려 볼 수 있다
# (common/harness-tests/next-role.sh — 케이스는 cases/next-role/).
#
# 받는 값 (환경변수):
#   VERDICT     PASS | CHANGES_REQUESTED   마지막 리뷰 판정. 리뷰 전이면 빈 값
#   ROUNDS      같은 PR 을 지금까지 몇 번 봤나
#   MAX_ROUNDS  그 상한 (settings.env 의 CLAUDE_MAX_ROUNDS)
#   STEP        지금까지 노드가 실행된 횟수 (state.sh 의 step)
#   MAX_STEPS   그 상한 (settings.env 의 CLAUDE_MAX_STEPS)
#   BROKEN      상태를 읽지 못했다는 표시 (state.sh 의 broken)
#   HAS_PAT     true | false               AGENT_PAT 이 있나
#
# 내는 값 (stdout 한 단어):
#   done       더 부를 역할이 없다. 루프를 끝낸다
#   human      자동으로 이어갈 수 없다. 사람을 부른다
#   loop-off   PAT 이 없어 재작업 루프가 꺼져 있다
#   <역할 이름>  .github/agent/nodes/<이름>.md 가 있는 역할
#
# **왜 그렇게 정했는지는 stderr 에 한 줄로 낸다.** stdout 은 대조할 수 있게 한 단어로 두고,
# 사람에게 남길 말은 따로 보낸다 — 부르는 쪽이 이유를 짐작해 지어내지 않게.
#
# 규칙은 위에서 아래로 읽는다. **먼저 걸리는 것이 이긴다.**
# 멈추는 조건을 앞에 둔 것은 일부러다 — 판별이 안 될 때 계속 도는 쪽이 아니라
# 멈추는 쪽으로 떨어져야 한다. 오늘은 이 둘이 없어서, 상태를 못 읽어도 몇 번을 돌았어도
# 계속 fix 를 불렀다.

set -u

VERDICT="${VERDICT:-}"
ROUNDS="${ROUNDS:-0}"
MAX_ROUNDS="${MAX_ROUNDS:-0}"
STEP="${STEP:-0}"
MAX_STEPS="${MAX_STEPS:-0}"
BROKEN="${BROKEN:-0}"
HAS_PAT="${HAS_PAT:-false}"

say() { printf '%s\n' "$1" >&2; }

# ① 상태를 못 읽었다. 몇 번 돌았는지도 무엇을 했는지도 모르는 채로 이어가지 않는다.
if [ "$BROKEN" = "1" ]; then
    say "루프 상태를 읽지 못했어요."
    echo "human"
    exit 0
fi

# ② 횟수를 숫자로 읽을 수 없다. ① 과 같은 갈래다 — 받은 값을 못 믿는다.
case "$STEP$MAX_STEPS$ROUNDS$MAX_ROUNDS" in
    '' | *[!0-9]*) say "루프 횟수를 숫자로 읽지 못했어요."; echo "human"; exit 0 ;;
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

# ④ 같은 PR 을 너무 많이 봤다.
if [ "$ROUNDS" -ge "$MAX_ROUNDS" ]; then
    say "리뷰 ${ROUNDS}회 후에도 지적이 남아 자동 재작업을 멈춰요."
    echo "human"
    exit 0
fi

# ⑤ 노드가 너무 많이 돌았다. ④ 와 다른 상한이다 —
#    저쪽은 같은 PR 을 몇 번 다시 보는지이고, 이쪽은 작업 하나에서 노드가 통틀어 몇 번 돌았는지다.
if [ "$STEP" -ge "$MAX_STEPS" ]; then
    say "노드가 ${STEP}번 돌아 상한(${MAX_STEPS})에 닿았어요."
    echo "human"
    exit 0
fi

# ⑥ GITHUB_TOKEN 으로 만든 커밋은 다른 워크플로를 깨우지 못해서, PAT 이 없으면 루프가 안 돈다.
#    도는 척하고 멈추는 것보다 꺼져 있다고 말하는 편이 낫다.
if [ "$HAS_PAT" != "true" ]; then
    say "AGENT_PAT 이 없어 재작업 루프가 꺼져 있어요."
    echo "loop-off"
    exit 0
fi

# ⑦ 지적이 남았다. 고치는 역할은 fix 하나다.
#
#    영역별로 나누고 싶을 수 있다(백엔드 지적이면 백엔드만 고치는 역할). 지금은 안 한다 —
#    api·web 노드의 지시문은 "기능을 구현한다"이지 "지적을 고친다"가 아니라서,
#    지적을 그쪽에 넘기면 시키는 일과 역할이 어긋난다. 나누려면 그런 역할 파일이 먼저 있어야 한다.
if [ "$VERDICT" = "CHANGES_REQUESTED" ]; then
    echo "fix"
    exit 0
fi

# ⑧ 판정이 없거나 모르는 값이다. 리뷰가 돌지 않았거나 형식이 바뀐 것이라 사람이 봐야 한다.
say "리뷰 판정을 알 수 없어요 (${VERDICT:-없음})."
echo "human"
