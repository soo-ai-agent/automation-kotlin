"""🔒 기능 본체 — 디스패처. claude-dispatch.yml 이 10분마다 두 번 부른다.

    python3 .github/agent/dispatch.py start     # 1·2 라벨 붙은 이슈를 찾아 일꾼 착수
    python3 .github/agent/dispatch.py cleanup   # 3~6 끝난 이슈·PR·브랜치 정리

두 모드를 나눈 이유는 Actions 화면에서 어느 쪽이 실패했는지 바로 보이게 하려는 것이다.
정리(cleanup)는 착수(start)가 실패해도 돈다.

수정 전에 common/docs/automation-spec.md 3절(완료 후 무인 정리)의 불변 조건을 먼저 읽는다.
핵심은 하나다 — **청소는 보수적으로.** 판단이 안 서면 지우지 않는 쪽으로 떨어져야 한다.

환경변수: REPO · GH_TOKEN · DEF(기본 브랜치) · HAS_PAT
"""
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request

# "이걸 건드릴까"는 dispatch_rules 가 정하고, 여기서는 묻고 그대로 실행한다.
# 판단을 이 파일에 되돌려 놓으면 하네스가 그것을 돌려 볼 수 없게 된다.
import dispatch_rules

REPO = os.environ["REPO"]
TOKEN = os.environ["GH_TOKEN"]
DEF = os.environ["DEF"]
# PAT 이 없으면 착수만 못 하고 정리는 돈다.
# GITHUB_TOKEN 으로 workflow_dispatch 를 걸어도 워크플로가 깨어나지 않기 때문이다.
CAN_START = os.environ.get("HAS_PAT") == "true"
API = "https://api.github.com"

REPORT_MARK = "📦 하위 작업 완료 보고"   # 완료 보고 중복 게시를 막는 멱등 마커


# ── 공통 도구 ────────────────────────────────────────────────

def api(path, data=None, method="GET"):
    req = urllib.request.Request(
        f"{API}/repos/{REPO}/{path}", method=method,
        headers={
            "Authorization": f"Bearer {TOKEN}",
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
            "Content-Type": "application/json",
        },
        data=json.dumps(data).encode() if data is not None else None)
    body = urllib.request.urlopen(req).read()   # DELETE·204 는 빈 응답
    return json.loads(body) if body else None


def issues(labels):
    q = urllib.parse.urlencode({"labels": labels, "state": "open", "per_page": 50})
    # /issues 는 PR 도 함께 준다 — pull_request 키가 있는 것은 걸러낸다
    return [it for it in api(f"issues?{q}") if "pull_request" not in it]


def labels_of(it):
    return [lb["name"] for lb in it.get("labels", [])]


def prs(branch, state="all"):
    owner = REPO.split("/")[0]
    q = urllib.parse.urlencode({"head": f"{owner}:{branch}", "state": state, "per_page": 20})
    return api(f"pulls?{q}")


# ── start — 라벨이 붙은 이슈를 찾아 일꾼을 부른다 ──────────────

def trigger_worker(number, extra):
    inputs = {"issue": str(number), "context_type": "issue"}
    inputs.update(extra)
    # prompt 는 넘기지 않는다 — 노드가 이슈 본문을 직접 읽는다 (입력 길이 제한 회피)
    api("actions/workflows/claude-agent.yml/dispatches",
        data={"ref": DEF, "inputs": inputs}, method="POST")
    api(f"issues/{number}/labels", data={"labels": ["claude-sent"]}, method="POST")


def start():
    """1·2) 라벨이 붙은 열린 이슈마다 착수할지 묻고, 답대로 일꾼을 부른다."""
    if not CAN_START:
        print("AGENT_PAT 없음 — 착수를 건너뜁니다 (정리는 그대로 돕니다)")
        return

    checked = sent = 0
    for it in issues("claude,claude-split"):
        checked += 1
        number = it["number"]
        decision = dispatch_rules.start_issue(CAN_START, labels_of(it))
        if decision == "skip":
            continue
        trigger_worker(number, {"node": "split"} if decision == "split" else {})
        sent += 1
        print(f'issue #{number} {"분할 " if decision == "split" else ""}착수')

    print(f"검사 {checked}건, 착수 {sent}건")


# ── cleanup — 끝난 것을 치운다 ────────────────────────────────

def report_split_parents():
    """3) 분할 상위 이슈 — 닫힌 하위를 체크리스트에 체크하고, 전부 끝나면 하위 작업별
    결과 보고(수행 내용·커밋·변경 파일)를 달아 사람에게 넘긴다. 상위 마감은 사람 몫."""
    for it in issues("claude-split,claude-sent"):
        body = it.get("body") or ""
        boxes = re.findall(r"^- \[([ x])\] #(\d+)", body, re.M)
        if not boxes:
            continue
        changed, all_closed = False, True
        for mark, ref in boxes:
            if mark == "x":
                continue
            if api(f"issues/{ref}")["state"] == "closed":
                body = re.sub(rf"^- \[ \] #{ref}\b", f"- [x] #{ref}", body, flags=re.M)
                changed = True
            else:
                all_closed = False
        number = it["number"]
        if changed:
            api(f"issues/{number}", data={"body": body}, method="PATCH")
            print(f"issue #{number} 체크리스트 갱신")
        if not all_closed:
            continue
        notes = api(f"issues/{number}/comments?per_page=100")
        if any(REPORT_MARK in (n.get("body") or "") for n in notes):
            continue   # 보고는 한 번만 — 이후 마감은 사람이 한다
        lines = [f"{REPORT_MARK} — 모든 하위 작업이 끝났어요. 확인 후 **이 이슈는 직접 닫아 주세요.**", ""]
        for _, ref in boxes:
            sub = api(f"issues/{ref}")
            lines.append(f"### #{ref} {sub['title']}")
            merged = [p for p in prs(f"claude/issue-{ref}") if p.get("merged_at")]
            if merged:
                pr = merged[0]
                lines.append(f"- 머지됨: {pr['html_url']}")
                for c in api(f"pulls/{pr['number']}/commits?per_page=10"):
                    lines.append("  - " + c["commit"]["message"].splitlines()[0])
                files = [f["filename"] for f in api(f"pulls/{pr['number']}/files?per_page=100")]
                head = ", ".join(f"`{p}`" for p in files[:12]) + (" 외" if len(files) > 12 else "")
                lines.append(f"- 변경 파일 {len(files)}개: {head}")
            else:
                lines.append("- 머지된 PR 없음 — 코드 변경 없이 종료 (하위 이슈의 🤖 코멘트 참고)")
            lines.append("")
        api(f"issues/{number}/comments", data={"body": "\n".join(lines)}, method="POST")
        print(f"issue #{number} 완료 보고 게시 — 마감은 사람 몫")


def close_merged_issues():
    """4) 마감 청소 — 머지된 PR 이 있는데 열려 있는 이슈를 닫는다."""
    for it in issues("claude,claude-sent"):
        number = it["number"]
        found = prs(f"claude/issue-{number}")
        if dispatch_rules.close_issue(
                labels_of(it),
                any(p["state"] == "open" for p in found),
                any(p.get("merged_at") for p in found)) != "close":
            continue
        api(f"issues/{number}/comments",
            data={"body": "✅ 연결된 PR 이 머지되어 있어 이슈를 닫아요."}, method="POST")
        api(f"issues/{number}", data={"state": "closed"}, method="PATCH")
        print(f"issue #{number} 머지 확인 — 마감")


def close_orphan_prs():
    """5) PR 청소 — 이슈가 닫힌 claude/issue-N 의 열린 PR 은 폐기된 작업이라 닫는다.
    변경 내용은 닫힌 PR 화면에 그대로 보존되므로 브랜치도 함께 지운다."""
    for pr in api("pulls?state=open&per_page=100") or []:
        src = pr["head"]["ref"]
        ref = dispatch_rules.issue_of(src)
        if ref is None:
            continue   # 사람 브랜치의 PR 은 건드리지 않는다
        try:
            state = api(f"issues/{ref}")["state"]
        except urllib.error.HTTPError:
            state = "unknown"   # 조회 실패 — 판단은 규칙이 한다
        if dispatch_rules.close_pr(src, state) != "close":
            continue
        api(f"issues/{pr['number']}/comments",
            data={"body": f"🧹 연결된 이슈 #{ref} 가 닫혀 있어 PR 도 닫아요. 변경 내용은 이 PR 에 보존돼요."},
            method="POST")
        api(f"pulls/{pr['number']}", data={"state": "closed"}, method="PATCH")
        try:
            api("git/refs/heads/" + urllib.parse.quote(src), method="DELETE")
        except urllib.error.HTTPError:
            pass
        print(f'PR #{pr["number"]} 닫음 (이슈 #{ref} 닫힘) + 브랜치 {src} 삭제')


def delete_merged_branches():
    """6) 브랜치 청소 — 기본 브랜치에 다 들어간 claude/* 브랜치를 지운다.
    GitHub 브랜치 API 에는 merged 플래그가 없어 compare 의 ahead_by 로 판정한다."""
    for br in api("branches?per_page=100") or []:
        name = br["name"]
        if not name.startswith("claude/"):
            continue   # 남의 브랜치는 PR 조회조차 하지 않는다
        try:
            ahead = api(f"compare/{urllib.parse.quote(DEF)}...{urllib.parse.quote(name)}").get("ahead_by")
        except urllib.error.HTTPError:
            ahead = None   # 조회 실패 — 판단은 규칙이 한다
        if dispatch_rules.delete_branch(
                name, any(p["state"] == "open" for p in prs(name)), ahead) != "delete":
            continue
        try:
            api("git/refs/heads/" + urllib.parse.quote(name), method="DELETE")
            print(f"브랜치 {name} 삭제 (머지 완료)")
        except urllib.error.HTTPError:
            pass


def cleanup():
    report_split_parents()
    close_merged_issues()
    close_orphan_prs()
    delete_merged_branches()


# ── 진입점 ───────────────────────────────────────────────────

MODES = {"start": start, "cleanup": cleanup}

if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else ""
    if mode not in MODES:
        sys.exit(f"사용법: dispatch.py [{' | '.join(MODES)}]")
    MODES[mode]()
