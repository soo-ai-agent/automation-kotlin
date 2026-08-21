#!/usr/bin/env bash
# spec-kit(SDD) 켜기 — 스펙을 먼저 쓰고 그 스펙으로 구현하는 방식을 이 저장소에 깝니다.
#
# 사용 (저장소를 clone 받은 곳에서):
#   bash .github/agent/setup-speckit.sh
#
# 선택 사항입니다. 이 스크립트를 돌리지 않아도 기존 이슈 기반 흐름은 그대로 돕니다.
#
# 준비물:
#   uv     파이썬 도구 설치기. 없으면 이 스크립트가 설치 방법을 안내하고 멈춥니다.
#   curl   최신 릴리스를 확인할 때 씁니다.
#
# 하는 일 다섯 가지:
#   0. 쓸 버전을 정한다 — 처음이면 그때의 최신 릴리스를 찾아 파일에 적어 고정
#   1. specify CLI 를 그 버전으로 설치
#   2. 이 저장소에 spec-kit 을 초기화 (.specify/ 와 .claude/skills/speckit-* 생성)
#   3. 한국어 산출물 템플릿(common/speckit-ko)을 프리셋으로 등록
#   4. 한국어판이 실제로 선택되는지 확인
#
# ⚠️ speckit-* 스킬 10종이 우리 규칙 스킬과 **같은 폴더**(.claude/skills/)에 깔립니다.
#    이름 앞자리로 구분되고 .gitignore 가 걸러 내지만, 스킬 목록을 볼 때 섞여 보입니다.
#
# 몇 번을 다시 실행해도 안전해요 — 이미 있는 것은 지우고 다시 깝니다.

set -euo pipefail

PRESET_DIR="common/speckit-ko"
PRESET_ID="korean"

# 이 프로젝트가 쓰는 spec-kit 버전. **첫 설치 때 그 시점의 최신 릴리스로 정해져 여기 적힌다.**
# 정해진 뒤에는 이 파일이 기준이라, 나중에 clone 한 사람도 같은 버전을 받는다. 커밋한다.
PIN_FILE="$PRESET_DIR/speckit-version.txt"

# 한국어 번역이 기준으로 삼은 상류 릴리스. 번역을 갱신한 사람이 함께 고친다.
BASELINE_FILE="$PRESET_DIR/translated-against.txt"

cd "$(dirname "$0")/../.."

# ── 0. 준비물 확인 ─────────────────────────────────────────
if ! command -v uv >/dev/null 2>&1; then
  cat <<'EOF'
uv 가 필요해요. 아래 한 줄로 설치한 뒤 다시 실행하세요.

  curl -LsSf https://astral.sh/uv/install.sh | sh

설치 후 새 셸을 열거나 `source ~/.bashrc` 로 PATH 를 다시 읽어야 합니다.
설치 방법 전체: https://docs.astral.sh/uv/getting-started/installation/
EOF
  exit 1
fi

command -v curl >/dev/null 2>&1 || { echo "curl 이 필요해요."; exit 1; }

# 상류의 최신 릴리스 태그를 찾는다.
resolve_latest() {
  local json
  json=$(curl -fsSL --max-time 20 \
    https://api.github.com/repos/github/spec-kit/releases/latest 2>/dev/null) || return 1
  if command -v python3 >/dev/null 2>&1; then
    printf '%s' "$json" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tag_name",""))' 2>/dev/null
  else
    printf '%s' "$json" | grep -m1 '"tag_name"' \
      | sed -E 's/.*"tag_name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/'
  fi
}

# ── 0. 쓸 버전 정하기 ──────────────────────────────────────
# 우선순위: 환경변수 > 이미 고정된 파일 > 지금의 최신 릴리스
#   SPECKIT_VERSION=v0.17.0  특정 버전으로
#   SPECKIT_VERSION=latest   지금의 최신으로 다시 고정 (버전 올릴 때)
NEWLY_PINNED=0
VERSION="${SPECKIT_VERSION:-}"

if [ "$VERSION" = "latest" ]; then
  VERSION=""
elif [ -z "$VERSION" ] && [ -s "$PIN_FILE" ]; then
  VERSION=$(tr -d '[:space:]' < "$PIN_FILE")
fi

if [ -z "$VERSION" ]; then
  echo "0/4 최신 릴리스 확인"
  VERSION=$(resolve_latest || true)
  if [ -z "$VERSION" ]; then
    echo "최신 릴리스를 확인하지 못했어요. 네트워크를 확인하거나 버전을 직접 주세요."
    echo "  SPECKIT_VERSION=<태그> bash .github/agent/setup-speckit.sh"
    echo "  태그 목록: https://github.com/github/spec-kit/releases"
    exit 1
  fi
else
  echo "0/4 쓸 버전: $VERSION"
fi

# 고정 파일을 항상 실제로 설치할 버전과 맞춘다.
# 이렇게 해야 SPECKIT_VERSION 으로 올린 버전이 다음 실행에서 되돌아가지 않는다.
CURRENT_PIN=""
[ -s "$PIN_FILE" ] && CURRENT_PIN=$(tr -d '[:space:]' < "$PIN_FILE")
if [ "$CURRENT_PIN" != "$VERSION" ]; then
  printf '%s\n' "$VERSION" > "$PIN_FILE"
  NEWLY_PINNED=1
  echo "     $VERSION 로 고정 → $PIN_FILE"
fi

# 번역이 기준 삼은 릴리스와 다르면 알려 준다.
# 번역본이 기본 템플릿을 이기기 때문에, 상류가 개선돼도 조용히 가려질 수 있다.
BASELINE=""
[ -s "$BASELINE_FILE" ] && BASELINE=$(tr -d '[:space:]' < "$BASELINE_FILE")
if [ -n "$BASELINE" ] && [ "$BASELINE" != "$VERSION" ]; then
  echo
  echo "⚠️  한국어 템플릿은 $BASELINE 기준으로 번역됐는데 설치할 버전은 $VERSION 입니다."
  echo "    그 사이에 상류 템플릿이 바뀌었다면 그 개선이 조용히 가려집니다."
  echo "    $PRESET_DIR/README.md 의 '갱신 절차' 로 변경 여부를 확인하세요."
  echo
fi

# ── 1. specify CLI 설치 ────────────────────────────────────
echo "1/4 specify CLI ${VERSION} 설치"
if ! uv tool install specify-cli \
  --from "git+https://github.com/github/spec-kit.git@${VERSION}" \
  --force >/dev/null 2>&1; then
  echo "specify CLI 설치에 실패했어요. 아래로 다시 돌려 원인을 보세요."
  echo "  uv tool install specify-cli --from git+https://github.com/github/spec-kit.git@${VERSION} --force"
  exit 1
fi
echo "     $(specify --version 2>/dev/null || echo '설치됨')"

# ── 2. 저장소에 초기화 ─────────────────────────────────────
# 옵션 이름은 버전마다 다르다 (예: --non-interactive 는 v0.16.5 에 있고 v0.16.4 에는 없다).
# 최신을 따라가는 방식이라, 있는 옵션만 골라 붙인다.
echo "2/4 저장소에 spec-kit 초기화"
INIT_HELP=$(specify init --help 2>&1 || true)
INIT_ARGS=(--here --force)
for opt in --non-interactive; do
  printf '%s' "$INIT_HELP" | grep -q -- "$opt" && INIT_ARGS+=("$opt")
done
printf '%s' "$INIT_HELP" | grep -q -- "--integration" && INIT_ARGS+=(--integration claude)
printf '%s' "$INIT_HELP" | grep -q -- "--script" && INIT_ARGS+=(--script sh)

if ! specify init "${INIT_ARGS[@]}" >/dev/null 2>&1; then
  echo "초기화에 실패했어요. 이 버전($VERSION)의 옵션이 다를 수 있습니다."
  echo "  아래로 직접 돌려 원인을 보세요."
  echo "  specify init ${INIT_ARGS[*]}"
  echo "  또는 최신으로 다시 고정하세요: SPECKIT_VERSION=latest bash $0"
  exit 1
fi
echo "     .specify/ 와 .claude/skills/speckit-* 생성"

# ── 3. 한국어 프리셋 등록 ──────────────────────────────────
# 원본은 common/speckit-ko 에 두고 여기서 등록한다. .specify/ 는 설치물이라
# .gitignore 대상이어서, 번역본을 그 안에 두면 무시 규칙에 함께 걸린다.
echo "3/4 한국어 산출물 템플릿 등록"
# 이미 깔려 있으면 add 가 거부하므로 먼저 지운다. 없을 때 지우는 것은 실패해도 괜찮다.
# `preset list` 출력을 뒤져 있는지 확인하지 않는다 — 표 형식이라 줄바꿈 위치에 따라
# 이름이 잘려 검색이 빗나간다. 무조건 지우고 무조건 다시 등록하는 편이 확실하다.
specify preset remove "$PRESET_ID" >/dev/null 2>&1 || true
# priority 는 낮을수록 먼저 선택된다.
if ! specify preset add --dev "$PRESET_DIR" --priority 1 >/dev/null 2>&1; then
  echo "프리셋 등록에 실패했어요. 아래로 다시 돌려 원인을 보세요."
  echo "  specify preset add --dev $PRESET_DIR --priority 1"
  exit 1
fi
echo "     $PRESET_DIR → 프리셋 '$PRESET_ID'"

# ── 4. 한국어판이 실제로 선택되는지 확인 ───────────────────
echo "4/4 확인"
FAILED=0
for t in spec-template plan-template tasks-template checklist-template; do
  RESOLVED=$(specify preset resolve "$t" 2>/dev/null || true)
  if printf '%s' "$RESOLVED" | grep -q "$PRESET_ID"; then
    echo "     $t — 한국어판"
  else
    echo "     $t — ⚠️ 한국어판이 아님"
    FAILED=1
  fi
done

if [ "$FAILED" -ne 0 ]; then
  echo
  echo "일부 템플릿이 한국어판으로 잡히지 않았습니다. 아래로 어느 파일이 선택됐는지 보세요."
  echo "  specify preset resolve spec-template"
  exit 1
fi

if [ "$NEWLY_PINNED" -eq 1 ]; then
  cat <<EOF

📌 이 프로젝트의 spec-kit 버전을 $VERSION 으로 정했습니다. **커밋하세요.**

  git add $PIN_FILE && git commit -m "chore:spec-kit 버전을 $VERSION 으로 고정"

이 파일이 있어야 나중에 clone 한 사람도 같은 버전을 받습니다.
나중에 올릴 때는 SPECKIT_VERSION=latest 로 다시 돌리세요.
EOF
fi

cat <<EOF

끝났습니다. 다음은 이렇게 씁니다.

  /speckit-constitution   프로젝트 규칙을 정한다 — 규칙 사본이 아니라
                          .claude/skills/ 와 common/docs/code-review/rules.md 를
                          가리키게 쓰고, "산출물은 한국어로 작성한다" 를 넣으세요.
  /speckit-specify        만들 것을 스펙으로 적는다 (specs/ 에 생긴다)
  /speckit-clarify        모호한 곳을 질문으로 뽑아 좁힌다 (선택)
  /speckit-plan           구현 계획을 세운다
  /speckit-tasks          작업으로 쪼갠다
  /speckit-analyze        스펙·계획·작업이 서로 어긋나지 않는지 본다 (선택)
  /speckit-implement      구현한다

결과가 스펙과 어긋나면 코드를 직접 고치지 말고 스펙으로 돌아가 다시 정의하세요.

CI 노드(GitHub Actions)는 이 도구를 쓰지 않습니다. 노드가 쓸 수 있는 명령이
git·gradle·npm 으로 제한돼 있어서, 스펙은 로컬에서 만들어 커밋하고
노드는 커밋된 specs/ 를 읽어 구현합니다.
EOF
