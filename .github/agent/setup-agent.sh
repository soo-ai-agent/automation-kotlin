#!/usr/bin/env bash
# 에이전트 세팅 원커맨드 — 라벨·시크릿·워크플로 권한·브랜치 보호를 GitHub API 로 만들어요.
#
# 사용 (저장소를 clone 받은 곳에서):
#   CLAUDE_CODE_OAUTH_TOKEN=<발급값> AGENT_PAT=<PAT> bash .github/agent/setup-agent.sh
#
# 준비물 — 이 두 가지만 사람이 직접 발급해요 (대화형 로그인이라 자동화 불가):
#   CLAUDE_CODE_OAUTH_TOKEN   로컬에서 `claude setup-token` 실행 → 출력값
#   AGENT_PAT                 GitHub Settings → Developer settings → Personal access tokens
#                             → Fine-grained token, 이 저장소 대상으로
#                             Contents / Pull requests / Issues / Actions 모두 Read and write
#
# 선택 환경변수:
#   REPO   기본값은 현재 디렉터리의 origin (예: myorg/myrepo)
#
# 몇 번을 다시 실행해도 안전해요 — 이미 있는 것은 건너뜁니다.

set -euo pipefail

command -v gh >/dev/null || { echo "gh CLI 가 필요해요: https://cli.github.com"; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "먼저 'gh auth login' 하세요"; exit 1; }

REPO="${REPO:-$(gh repo view --json nameWithOwner --jq .nameWithOwner)}"
DEF=$(gh repo view "$REPO" --json defaultBranchRef --jq .defaultBranchRef.name)
echo "대상: ${REPO} (기본 브랜치 ${DEF})"

# ── 1. 라벨 (자동 착수·자동 머지 규약) ─────────────────────
ensure_label() { # $1=이름 $2=색 $3=설명
  if gh label list --repo "$REPO" --json name --jq '.[].name' | grep -qx "$1"; then
    echo "라벨 $1 — 이미 있음"
  else
    gh label create "$1" --repo "$REPO" --color "$2" --description "$3" >/dev/null
    echo "라벨 $1 — 생성"
  fi
}
ensure_label claude       6666c4 "이 이슈를 Claude 에게 (착수 동의)"
ensure_label claude-split c46666 "하위 이슈로 쪼개 달라"
ensure_label claude-sent  cccccc "디스패처가 착수함 — 떼면 재착수"
ensure_label claude-made  66c4a3 "에이전트가 만든 하위 이슈 — 자동 머지 대상"

# ── 2. 시크릿 ─────────────────────────────────────────────
ensure_secret() { # $1=이름 $2=값
  [ -n "${2:-}" ] || { echo "시크릿 $1 — 값이 없어 건너뜀"; return 0; }
  if gh secret list --repo "$REPO" --json name --jq '.[].name' | grep -qx "$1"; then
    echo "시크릿 $1 — 이미 있음 (그대로 둠)"
  else
    printf '%s' "$2" | gh secret set "$1" --repo "$REPO" >/dev/null
    echo "시크릿 $1 — 등록"
  fi
}
ensure_secret CLAUDE_CODE_OAUTH_TOKEN "${CLAUDE_CODE_OAUTH_TOKEN:-}"
ensure_secret AGENT_PAT "${AGENT_PAT:-}"

# ── 3. 워크플로 권한 ──────────────────────────────────────
# 일꾼이 push·PR·코멘트를 하려면 쓰기 권한이 열려 있어야 해요.
gh api -X PUT "repos/${REPO}/actions/permissions/workflow" \
  -F default_workflow_permissions=write \
  -F can_approve_pull_request_reviews=true >/dev/null \
  && echo "워크플로 권한 — 쓰기 허용" \
  || echo "워크플로 권한 — 설정 실패 (저장소 admin 권한 필요). Settings → Actions → General 에서 직접 켜세요"

# ── 4. 기본 브랜치 보호 ───────────────────────────────────
# 직접 푸시를 막아요. 리뷰어가 통과 PR 을 자동 머지하므로 AGENT_PAT 은 쓰기 권한이어야 해요.
if gh api "repos/${REPO}/branches/${DEF}/protection" >/dev/null 2>&1; then
  echo "브랜치 보호 (${DEF}) — 이미 있음"
else
  gh api -X PUT "repos/${REPO}/branches/${DEF}/protection" \
    --input - >/dev/null 2>&1 << JSON && echo "브랜치 보호 (${DEF}) — 설정" \
      || echo "브랜치 보호 (${DEF}) — 설정 실패 (private 저장소는 유료 플랜에서만 가능). 건너뜁니다"
{
  "required_status_checks": null,
  "enforce_admins": false,
  "required_pull_request_reviews": null,
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
JSON
fi

# ── 마무리 안내 ───────────────────────────────────────────
echo
echo "세팅 끝. 남은 것:"
gh secret list --repo "$REPO" --json name --jq '.[].name' | grep -qx CLAUDE_CODE_OAUTH_TOKEN \
  || echo "  - CLAUDE_CODE_OAUTH_TOKEN 이 아직 없어요: 'claude setup-token' 발급 후 이 스크립트를 다시 실행"
gh secret list --repo "$REPO" --json name --jq '.[].name' | grep -qx AGENT_PAT \
  || echo "  - AGENT_PAT 이 아직 없어요: 없으면 리뷰어·재작업 루프·디스패처가 동작하지 않아요"
echo "  - 백엔드 뼈대: backend/README.md 대로 Spring 멀티모듈을 올린다"
echo "  - 배포까지 원하면: Variables 에 DEPLOY_ENABLED=true (docs/deploy.md)"
echo
echo "확인: 이슈 하나에 claude 라벨을 붙이고 10분 안에 PR 이 열리는지 본다"
echo "      (급하면 gh workflow run claude-dispatch.yml --repo ${REPO} 로 즉시 폴링)"
