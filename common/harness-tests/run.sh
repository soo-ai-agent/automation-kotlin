#!/usr/bin/env bash
# 하네스 회귀 테스트 — 리뷰어가 "심어 둔 위반"을 여전히 잡는지 확인한다.
#
# 사용 (저장소 루트에서):
#   bash common/harness-tests/run.sh
#
# 언제 돌리나: 스킬·리뷰 규칙·헌법을 고친 뒤. 규칙을 고쳤는데 판정이 그대로인지,
# 반대로 멀쩡하던 변경이 갑자기 막히지는 않는지 본다.
#
# 준비물: claude CLI 로그인 (`claude setup-token`)
#
# ⚠️ 케이스 하나당 claude 호출 1건을 쓴다. 케이스를 늘리면 그만큼 늘어난다.
#    30건을 넘길 작업은 시작 전에 사람에게 승인받는다 (CLAUDE.md).

set -u

cd "$(dirname "$0")/../.."

command -v claude >/dev/null || { echo "claude CLI 가 필요해요: claude setup-token"; exit 1; }

PASS=0
FAIL=0

for case_file in common/harness-tests/cases/*.diff; do
  name=$(basename "$case_file" .diff)
  expected=$(head -n 1 "$case_file" | sed 's/^# expect: //')

  verdict=$(claude -p "너는 이 저장소의 코드 리뷰어다. 아래 근거만 보고 판정하라.

근거 (이 순서로 읽는다):
- common/docs/code-review/rules.md — MUST 를 어기면 머지 차단
- backend/.claude/skills/ — 백엔드 규칙 (kotlin-*)
- frontend/.claude/skills/ — 프론트엔드 규칙
- .claude/skills/ — 공통 규칙

첫 줄에 'VERDICT: PASS' 또는 'VERDICT: CHANGES_REQUESTED' 만 쓰고,
차단 사유가 있으면 근거가 된 규칙을 인용하라.

$(tail -n +2 "$case_file")" --output-format text 2>/dev/null | grep -m1 "VERDICT:")

  if printf '%s' "$verdict" | grep -q "$expected"; then
    printf 'PASS  %-28s %s\n' "$name" "$verdict"
    PASS=$((PASS + 1))
  else
    printf 'FAIL  %-28s 기대=%s 실제=%s\n' "$name" "$expected" "${verdict:-응답 없음}"
    FAIL=$((FAIL + 1))
  fi
done

printf '\n%d PASS · %d FAIL\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
