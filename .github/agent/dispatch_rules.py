"""🔒 기능 본체 — 디스패처가 "이걸 건드릴까"를 정하는 곳. dispatch.py 가 가져다 쓴다.

여기에는 GitHub 호출도 파일 쓰기도 없다. 값을 받아 한 단어를 돌려준다.
그래야 하네스가 GitHub 없이 판단을 통째로 돌려 볼 수 있다
(common/harness-tests/cases.sh — 케이스는 cases/dispatch/).

**청소는 보수적으로.** 판단이 안 서면 건드리지 않는 쪽으로 떨어진다. 이슈를 닫고 PR 을
닫고 브랜치를 지우는 판단이라, 틀리면 사람이 만든 것이 사라진다. 그래서 각 함수는
"해도 되는 이유"를 다 확인한 다음에만 손대는 답을 낸다.

파일 이름에 밑줄을 쓴 것은 dispatch.py 가 import 해야 해서다 — 파이썬은 이름에 하이픈이
들어간 모듈을 import 하지 못한다. 같은 폴더의 셸 도구들은 하이픈을 쓴다.

손으로 확인할 때 (하네스가 이 꼴로 부른다):

    HAS_PAT=true LABELS="claude" python3 .github/agent/dispatch_rules.py start
"""
import os
import sys

BRANCH_PREFIX = "claude/issue-"


def issue_of(head_ref):
    """브랜치 이름에서 이슈 번호를 꺼낸다. 판별이 안 되면 None.

    이슈 번호가 필요한 곳이 둘이라 해석은 여기 한 번만 적는다.
    """
    if not head_ref.startswith(BRANCH_PREFIX):
        return None
    rest = head_ref[len(BRANCH_PREFIX):]
    if not rest.isdigit():
        return None
    return rest


def start_issue(has_pat, labels):
    """라벨이 붙은 이슈를 착수시킬까. → skip | split | code

    claude-sent 는 이미 착수했다는 표시다. 그것이 가장 앞이라야 같은 이슈를 두 번 안 부른다.
    claude-split 이 claude 보다 앞인 것은, 둘 다 붙어 있으면 쪼개는 쪽이 먼저이기 때문이다.
    """
    if not has_pat:
        return "skip"   # GITHUB_TOKEN 으로 부른 워크플로는 깨어나지 않는다
    if "claude-sent" in labels:
        return "skip"
    if "claude-split" in labels:
        return "split"
    if "claude" in labels:
        return "code"
    return "skip"


def close_pr(head_ref, issue_state):
    """이슈가 닫힌 PR 을 닫을까. → close | keep

    issue_state 는 open · closed · unknown(조회 실패) 셋이다.
    unknown 을 closed 로 보면 살아 있는 PR 을 닫게 되므로 keep 으로 떨어진다.
    """
    if issue_of(head_ref) is None:
        return "keep"   # 사람이 만든 브랜치의 PR 은 건드리지 않는다
    if issue_state != "closed":
        return "keep"
    return "close"


def delete_branch(name, has_open_pr, ahead_by):
    """기본 브랜치에 다 들어간 브랜치를 지울까. → delete | keep

    ahead_by 는 기본 브랜치에 없는 커밋 수다. None 이면 조회에 실패한 것이고,
    그때는 지우지 않는다 — 못 물어봤다는 것이 없다는 뜻은 아니다.
    """
    if not name.startswith("claude/"):
        return "keep"   # 에이전트가 만든 브랜치만 지운다
    if has_open_pr:
        return "keep"   # 열린 PR 이 있으면 두고 본다
    if ahead_by != 0:
        return "keep"
    return "delete"


# ── 손으로 돌려 볼 때 쓰는 입구 ──────────────────────────────
# 하네스도 이 입구로 부른다. 값은 환경변수로 받고 답 한 단어를 낸다.

def _flag(name):
    return os.environ.get(name, "") == "true"


def _ahead_by():
    raw = os.environ.get("AHEAD_BY", "")
    return int(raw) if raw.isdigit() else None


COMMANDS = {
    "start": lambda: start_issue(_flag("HAS_PAT"), os.environ.get("LABELS", "").split()),
    "close-pr": lambda: close_pr(
        os.environ.get("HEAD_REF", ""), os.environ.get("ISSUE_STATE", "unknown")),
    "delete-branch": lambda: delete_branch(
        os.environ.get("BRANCH", ""), _flag("PR_OPEN"), _ahead_by()),
    "issue": lambda: issue_of(os.environ.get("HEAD_REF", "")) or "",
}

if __name__ == "__main__":
    command = sys.argv[1] if len(sys.argv) > 1 else ""
    if command not in COMMANDS:
        sys.exit(f"사용법: dispatch_rules.py [{' | '.join(COMMANDS)}]")
    print(COMMANDS[command]())
