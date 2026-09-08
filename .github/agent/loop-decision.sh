#!/usr/bin/env bash
# 🔒 기능 본체 — 리뷰를 통과한 PR 을 지금 머지할지 정하는 곳. claude-review.yml 이 부른다.
#
# 워크플로가 이 파일을 **기준 브랜치에서 꺼내** /tmp 로 복사한 뒤 실행한다.
# 자동 머지 게이트가 여기 있어서, PR 브랜치가 자기 머지 조건을 바꾸면 안 되기 때문이다.
#
# 여기에는 GitHub API 호출도 파일 쓰기도 없다. 값을 받아 결정 한 단어를 stdout 에 낸다.
# 그래야 하네스가 모델도 GitHub 도 없이 루프를 통째로 돌려 볼 수 있다
# (tests/cases.sh — 케이스는 cases/loop/).
#
# **여기는 머지만 정한다.** 다음에 무엇을 돌릴지는 next-role.sh 가 정한다 —
# 두 판단을 한 곳에 두면 "계속할까"를 양쪽이 각자 재게 되고, 상한을 하나 바꿀 때
# 두 군데를 고쳐야 한다.
#
# 받는 값 (환경변수):
#   VERDICT      PASS | CHANGES_REQUESTED   리뷰 판정
#   HEAD_REF     PR 의 head 브랜치 이름
#   AGENT_MADE   true | false | unknown     그 이슈에 claude-made 라벨이 있나
#
# 내는 값 (stdout 한 단어):
#   merge        자동 머지한다
#   human-merge  통과했지만 머지는 사람 몫이다
#   no-merge     지금 머지할 상황이 아니다 (지적이 남았거나 판정이 없다)

set -u

# 이 PR 이 딸린 이슈 번호. 브랜치명으로만 알 수 있고, 판별이 안 되면 빈 줄을 낸다.
# 자동 머지 게이트 ①이기도 하고 라벨을 물어볼 대상이기도 해서 두 곳이 이 답을 쓴다 —
# 그래서 해석은 여기 한 번만 적는다.
pr_issue() {
    case "${HEAD_REF:-}" in
        claude/issue-*) n="${HEAD_REF#claude/issue-}" ;;
        *) return 0 ;;
    esac
    case "$n" in '' | *[!0-9]*) return 0 ;; esac
    echo "$n"
}

# 인자로 issue 를 주면 결정 대신 그 번호만 낸다 — 워크플로가 라벨을 물어볼 때 쓴다.
if [ "${1:-}" = "issue" ]; then
    pr_issue
    exit 0
fi

VERDICT="${VERDICT:-}"
HEAD_REF="${HEAD_REF:-}"
AGENT_MADE="${AGENT_MADE:-unknown}"

if [ "$VERDICT" = "PASS" ]; then
    # 자동 머지 2중 게이트 — ① 브랜치명이 claude/issue-N 인가 ② 그 이슈가 claude-made 인가.
    # 둘 다 확실할 때만 머지한다. 판별이 안 되면 사람에게 넘긴다(안전 측 실패) —
    # 게이트 순서를 바꾸거나 unknown 을 통과시키면 사람이 올린 이슈의 PR 이 자동 머지된다.
    [ -n "$(pr_issue)" ] || { echo "human-merge"; exit 0; }
    [ "$AGENT_MADE" = "true" ] || { echo "human-merge"; exit 0; }
    echo "merge"
    exit 0
fi

# 통과가 아니면 머지할 상황이 아니다. 그다음에 무엇을 할지는 next-role.sh 가 정한다.
echo "no-merge"
