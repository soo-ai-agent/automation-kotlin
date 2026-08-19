#!/usr/bin/env bash
# 외부 API 대량 호출 경고 — PreToolUse(Bash) 훅.
#
# 규칙(CLAUDE.md "시작 전에 승인을 받는 작업"): 외부 API 를 30건 이상 호출하는 작업은
# 시작 전에 대상·예상 호출 수·쿼터 영향을 보고하고 승인을 받는다. 실검증도 예외가 아니다.
#
# 이 훅은 "반복 + HTTP 호출" 조합을 감지해 사용자에게 확인 창을 띄운다. 막지는 않는다 —
# 30건 미만이거나 무해한 경우가 있어서, 판단은 사람이 한다.
#
# 한계: 스크립트 안에서 부르는 호출(`npm run sync`, 배치 태스크)은 명령줄만 봐서는 모른다.
# 감지는 보조 수단이고, 규칙을 지킬 책임은 에이전트에게 있다.
set -u

payload="$(cat)"

# 로컬 대상(개발 서버 헬스체크 등)은 외부 쿼터와 무관하다.
if printf '%s' "$payload" | grep -Eq 'localhost|127\.0\.0\.1|0\.0\.0\.0'; then
    exit 0
fi

http_client='curl|wget|httpie|xh |Invoke-WebRequest'
repetition='for |while |xargs|seq |parallel|repeat '

if printf '%s' "$payload" | grep -Eq "$http_client" &&
    printf '%s' "$payload" | grep -Eq "$repetition"; then
    cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"외부 API 를 반복 호출하는 명령으로 보입니다.\n30건 이상이면 시작 전에 ① 대상 ② 예상 호출 수 ③ 쿼터 영향을 보고하고 승인을 받아야 합니다 (CLAUDE.md '시작 전에 승인을 받는 작업', backend/.claude/skills/kotlin-client).\n실검증도 예외가 아닙니다. 30건 미만이거나 쿼터와 무관하면 그대로 진행하세요."}}
JSON
fi

exit 0
