#!/usr/bin/env bash
# 하네스 회귀 테스트 — 리뷰어가 "심어 둔 위반"을 여전히 잡는지 확인한다.
#
# 사용 (저장소 루트에서):
#   bash common/harness-tests/run.sh             # 전부 (backend + frontend)
#   bash common/harness-tests/run.sh backend     # 백엔드 케이스만
#   bash common/harness-tests/run.sh frontend    # 프론트 케이스만
#
# 영역은 **어느 케이스를 돌릴지**만 고른다. 리뷰어를 부르는 방식은 영역과 무관하게
# 언제나 .github/workflows/claude-review.yml 과 똑같다 — 역할 지시문·리뷰 규칙 전문·
# 통과 기준·--add-dir 까지 같은 것을 쓴다. 하네스가 자기만의 리뷰어를 만들면
# 하네스가 통과해도 실제 리뷰어의 회귀는 못 잡는다.
#
# 모델을 부르지 않는 형식 검사는 static.sh 가 따로 한다. 그쪽을 먼저 돌리면 싸게 걸러진다.
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

ROLE_FILE=".github/agent/review-role.md"
SETTINGS_FILE=".github/agent/settings.env"

usage() {
    cat << USAGE
사용법: bash common/harness-tests/run.sh [backend|frontend|all]

  backend    common/harness-tests/cases/backend/
  frontend   common/harness-tests/cases/frontend/
  all        둘 다 (기본값)

영역은 어느 케이스를 돌릴지만 고른다. 리뷰어는 언제나 실제 리뷰어와 같은 방식으로 불린다.

케이스를 늘리려면 해당 영역 폴더에 .diff 를 더하고, 첫 줄에
'# expect: PASS' 또는 '# expect: CHANGES_REQUESTED' 를 적는다.
USAGE
}

AREA="${1:-all}"
case "$AREA" in
    backend | be)
        AREA="backend"
        CASE_DIRS="common/harness-tests/cases/backend"
        ;;
    frontend | fe)
        AREA="frontend"
        CASE_DIRS="common/harness-tests/cases/frontend"
        ;;
    all)
        CASE_DIRS="common/harness-tests/cases/backend common/harness-tests/cases/frontend"
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
[ -f "$ROLE_FILE" ] || { echo "리뷰어 역할 지시문이 없어요: $ROLE_FILE"; exit 1; }

# 통과 기준과 규칙 위치는 워크플로와 같은 곳에서 읽는다 — 여기 베껴 적으면 둘이 어긋난다.
# shellcheck source=/dev/null
. "$SETTINGS_FILE"

echo "▶ 하네스 회귀 — $AREA"

PASS=0
FAIL=0

for case_dir in $CASE_DIRS; do
  for case_file in "$case_dir"/*.diff; do
    [ -e "$case_file" ] || continue
    name=$(basename "$case_file" .diff)
    expected=$(head -n 1 "$case_file" | sed 's/^# expect: //')

    # 입력 구조는 claude-review.yml 의 '리뷰' 스텝과 같다 (기준 스펙 절만 없다 —
    # 케이스가 이슈에 딸린 스펙을 갖지 않기 때문이다).
    {
      printf '## 리뷰 규칙\n\n'
      find "$CLAUDE_REVIEW_RULES_DIR" -name '*.md' -type f -print0 2>/dev/null | sort -z | xargs -0 -r cat
      printf '\n\n## 통과 기준\n\n%s\n' "$CLAUDE_REVIEW_BAR"
      printf '\n\n## DIFF\n\n'
      tail -n +2 "$case_file"
    } > /tmp/harness-input.txt

    # --add-dir 은 하위 폴더의 스킬을 세션 스킬 목록에 올린다. 여러 폴더를 받는 옵션이라
    # 바로 뒤에 플래그가 아닌 것이 오면 그것까지 폴더로 먹으니 순서를 바꾸지 않는다.
    #
    # 출력은 파일로 받고 나서 고른다. grep -m1 로 바로 파이프하면 grep 이 첫 줄에서
    # 파이프를 닫아 claude 가 SIGPIPE 로 죽고, 그다음 케이스부터 줄줄이 빈 응답이 된다.
    claude --add-dir backend --add-dir frontend \
      --allowedTools "Read,Grep,Glob" \
      --output-format text -p "$(cat "$ROLE_FILE")" \
      < /tmp/harness-input.txt > /tmp/harness-output.txt 2> /tmp/harness-error.txt
    verdict=$(grep -m1 "VERDICT:" /tmp/harness-output.txt)

    if printf '%s' "$verdict" | grep -q "$expected"; then
      printf 'PASS  %-28s %s\n' "$name" "$verdict"
      PASS=$((PASS + 1))
    else
      printf 'FAIL  %-28s 기대=%s 실제=%s\n' "$name" "$expected" "${verdict:-응답 없음}"
      # 빈 응답일 때 원인을 남긴다 — "응답 없음"만 보면 무엇이 틀렸는지 알 수 없다
      [ -n "$verdict" ] || head -n 3 /tmp/harness-error.txt | sed 's/^/     └ /'
      FAIL=$((FAIL + 1))
    fi
  done
done

printf '\n%d PASS · %d FAIL\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
