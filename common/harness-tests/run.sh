#!/usr/bin/env bash
# 하네스 회귀 테스트 — 리뷰어가 "심어 둔 위반"을 여전히 잡는지 확인한다.
#
# 사용 (저장소 루트에서):
#   bash common/harness-tests/run.sh             # 전부 (backend + frontend)
#   bash common/harness-tests/run.sh backend     # 백엔드 케이스만
#   bash common/harness-tests/run.sh frontend    # 프론트 케이스만
#
# 영역 갈래는 launcher(bin/claude-skills.sh) 의 claude-be·claude-fe·claude-all 과 같다.
# 리뷰어도 그 영역의 스킬만 물고 돈다 — 하네스가 실제 세션과 다른 조건으로 돌면 회귀를 놓친다.
#
# 언제 돌리나: 스킬·리뷰 규칙·헌법을 고친 뒤. 규칙을 고쳤는데 판정이 그대로인지,
# 반대로 멀쩡하던 변경이 갑자기 막히지는 않는지 본다. 백엔드 스킬만 고쳤으면 backend 만 돌려도 된다.
#
# 준비물: claude CLI 로그인 (`claude setup-token`)
#
# ⚠️ 케이스 하나당 claude 호출 1건을 쓴다. 케이스를 늘리면 그만큼 늘어난다.
#    30건을 넘길 작업은 시작 전에 사람에게 승인받는다 (CLAUDE.md).

set -u

cd "$(dirname "$0")/../.."

usage() {
    cat << USAGE
사용법: bash common/harness-tests/run.sh [backend|frontend|all]

  backend    common/harness-tests/cases/backend/  — 리뷰어가 공통 + kotlin-* 스킬을 문다
  frontend   common/harness-tests/cases/frontend/ — 리뷰어가 공통 + frontend-* 스킬을 문다
  all        둘 다 (기본값)

케이스를 늘리려면 해당 영역 폴더에 .diff 를 더하고, 첫 줄에
'# expect: PASS' 또는 '# expect: CHANGES_REQUESTED' 를 적는다.
USAGE
}

# 영역마다 케이스 폴더와, 리뷰어에게 물릴 스킬이 다르다.
# --add-dir 이 없으면 하위 폴더의 스킬이 세션 스킬 목록에 오르지 않는다 — launcher 와 같은 이유다.
AREA="${1:-all}"
case "$AREA" in
    backend | be)
        AREA="backend"
        CASE_DIRS="common/harness-tests/cases/backend"
        ADD_DIRS="--add-dir backend"
        SKILL_SOURCES="- backend/.claude/skills/ — 백엔드 규칙 (kotlin-*)"
        ;;
    frontend | fe)
        AREA="frontend"
        CASE_DIRS="common/harness-tests/cases/frontend"
        ADD_DIRS="--add-dir frontend"
        SKILL_SOURCES="- frontend/.claude/skills/ — 프론트엔드 규칙 (frontend-*)"
        ;;
    all)
        CASE_DIRS="common/harness-tests/cases/backend common/harness-tests/cases/frontend"
        ADD_DIRS="--add-dir backend --add-dir frontend"
        SKILL_SOURCES="- backend/.claude/skills/ — 백엔드 규칙 (kotlin-*)
- frontend/.claude/skills/ — 프론트엔드 규칙 (frontend-*)"
        ;;
    -h | --help | help)
        usage
        exit 0
        ;;
    *)
        echo "모르는 영역: $AREA" >&2
        echo >&2
        usage >&2
        exit 2
        ;;
esac

command -v claude >/dev/null || { echo "claude CLI 가 필요해요: claude setup-token"; exit 1; }

echo "▶ 하네스 회귀 — $AREA"

PASS=0
FAIL=0

for case_dir in $CASE_DIRS; do
  for case_file in "$case_dir"/*.diff; do
    [ -e "$case_file" ] || continue
    name=$(basename "$case_file" .diff)
    expected=$(head -n 1 "$case_file" | sed 's/^# expect: //')

    # ADD_DIRS 는 따옴표 없이 펼친다 — 폴더 이름에 공백이 없어 낱말 분리가 그대로 인자가 된다.
    # --add-dir 은 폴더를 여러 개 받는 옵션이라 바로 뒤에 플래그가 아닌 것이 오면 그것까지 폴더로 먹는다.
    # 그래서 프롬프트 앞이 아니라 --output-format 앞에 둔다 — 순서를 바꾸면 프롬프트가 통째로 사라진다.
    verdict=$(claude $ADD_DIRS --output-format text -p "너는 이 저장소의 코드 리뷰어다. 아래 근거만 보고 판정하라.

근거 (이 순서로 읽는다):
- common/docs/code-review/rules.md — MUST 를 어기면 머지 차단
$SKILL_SOURCES
- .claude/skills/ — 공통 규칙
- 동작을 깨뜨리는 버그·처리되지 않은 엣지 케이스, diff 가 인용한 스펙(specs/)과 어긋나는 구현도 차단 사유다
- 스타일 취향·있으면 좋을 리팩터링은 차단하지 말고 PASS + 참고 코멘트로 남긴다

첫 줄에 'VERDICT: PASS' 또는 'VERDICT: CHANGES_REQUESTED' 만 쓰고,
차단 사유가 있으면 근거가 된 규칙을 인용하라.

$(tail -n +2 "$case_file")" 2>/dev/null | grep -m1 "VERDICT:")

    if printf '%s' "$verdict" | grep -q "$expected"; then
      printf 'PASS  %-28s %s\n' "$name" "$verdict"
      PASS=$((PASS + 1))
    else
      printf 'FAIL  %-28s 기대=%s 실제=%s\n' "$name" "$expected" "${verdict:-응답 없음}"
      FAIL=$((FAIL + 1))
    fi
  done
done

printf '\n%d PASS · %d FAIL\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
