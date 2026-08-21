#!/usr/bin/env bash
# 🔒 기능 본체 — 노드 하나가 Claude 를 실행하는 부분. claude-node.yml 의 ② 단계가 부른다.
#
# 하는 일은 둘이다.
#   1. 역할 지시문 + 작업 지시 + 커밋 규칙을 이어 붙여 프롬프트를 만든다
#   2. claude CLI 를 돌리고, 실패했는데 수습 노드가 지정돼 있으면 한 번 더 이어서 돌린다
#
# 워크플로가 이 파일을 **기본 브랜치에서 꺼내** /tmp 로 복사한 뒤 실행한다.
# 작업 브랜치가 이 파일을 고쳐도 그 잡의 실행 방식이 바뀌지 않아야 하기 때문이다.
#
# 미리 준비돼 있어야 하는 것 (claude-node.yml 의 ① 단계가 만든다):
#   /tmp/role.md         이 노드의 역할 지시문
#   /tmp/rescue-role.md  수습 노드의 역할 지시문 (RESCUE 가 있을 때만)
#   /tmp/body.md         작업 지시 본문
#   /tmp/stream.js       실행 로그 정리기
#
# 환경변수: NODE_NAME · RESCUE · CONTEXT_TYPE · GITHUB_ENV
# 남기는 것: /tmp/claude-out.txt(최종 보고), GITHUB_ENV 에 CLAUDE_STATUS·NODE_LABEL

set -o pipefail

# Claude 에게 허용할 명령. git 과 검증 명령뿐이다 —
# 이슈·PR·라벨 같은 API 호출은 셸이 하고 Claude 에게 토큰을 주지 않는다.
ALLOWED="Bash(git add:*),Bash(git commit:*),Bash(git status:*),Bash(git diff:*),Bash(git log:*),Bash(./gradlew:*),Bash(npm:*),Bash(cd backend && ./gradlew:*),Bash(cd frontend && npm:*)"

build_prompt() { # $1=역할 파일, $2=출력 파일
  : > "$2"
  [ -s "$1" ] && printf '%s\n\n' "$(cat "$1")" >> "$2"
  printf '## 작업\n\n%s\n\n' "$(cat /tmp/body.md)" >> "$2"

  if [ "$CONTEXT_TYPE" = "issue" ] && [ "$NODE_NAME" != "split" ]; then
    if grep -q 'specs/' /tmp/body.md 2>/dev/null; then
      # 스펙이 있으면 그것이 기준이다. 이슈 본문이 짧아도 명세를 새로 지어내면 안 된다 —
      # 지어낸 명세가 이슈 본문에 박혀 이후 노드의 기준이 되면서 스펙을 밀어낸다.
      printf '위 작업이 가리키는 specs/ 문서(spec.md · plan.md · tasks.md)를 **먼저 읽고** 그것을 기준으로 구현해라.\n' >> "$2"
      printf '이슈 본문이 짧아도 명세를 새로 만들지 마라. 기준은 이미 스펙에 있다.\n' >> "$2"
      printf '구현이 스펙과 어긋나면 코드를 고쳐 맞춘다. 스펙을 고쳐 코드에 맞추지 마라.\n' >> "$2"
      printf '스펙 자체가 틀렸다고 판단되면 조용히 고치지 말고 보고해라.\n\n' >> "$2"
    else
      # 제목만 있는 이슈 보완 — 스펙이 없을 때만. 명세의 원본은 저장소가 아니라 이슈다
      printf '위 작업에 할 일 목록이나 완료 기준이 없거나 빈약하면, 구현 전에 네가 직접 정의해라:\n' >> "$2"
      printf '배경·할 일·완료 기준(체크박스)을 담은 .claude-spec.md 를 저장소 루트에 만들고(커밋 금지),\n' >> "$2"
      printf '그 완료 기준을 만족시키는 것까지가 이번 작업이다. 이미 충분히 구체적이면 이 파일은 만들지 마라.\n\n' >> "$2"
    fi
  fi

  printf '작업이 끝나면 변경을 논리 단위로 나눠 직접 git add / git commit 해줘.\n' >> "$2"
  printf '리팩터링과 기능 변경은 같은 커밋에 섞지 말고, 메시지는 <type>:<제목> 형식으로\n' >> "$2"
  printf '(type 소문자, 콜론 뒤 공백 없음: feat/fix/refactor/test/docs/chore 등).\n' >> "$2"
  printf '커밋 메시지와 최종 결과 보고는 한국어로 쓴다. 코드·식별자·경로는 원문 그대로 둔다.\n' >> "$2"
}

run_claude() { # $1=프롬프트 파일 → 종료코드를 STATUS 에
  STATUS=0
  claude -p "$(cat "$1")" \
    --permission-mode acceptEdits \
    --allowedTools "$ALLOWED" \
    --output-format stream-json --verbose \
    | tee /tmp/claude-stream.jsonl \
    | node /tmp/stream.js || STATUS=$?
  node /tmp/stream.js result /tmp/claude-stream.jsonl > /tmp/claude-out.txt
}

build_prompt /tmp/role.md /tmp/prompt.txt
echo "노드: $NODE_NAME${RESCUE:+ (수습: $RESCUE)}"
run_claude /tmp/prompt.txt

# 수습 — 실패했고 수습 노드가 지정돼 있으면, 같은 브랜치를 이어받아 완수시킨다
if [ "$STATUS" != "0" ] && [ -n "$RESCUE" ]; then
  echo "::warning::$NODE_NAME 실패(status $STATUS) — $RESCUE 노드로 수습 시작"
  cp /tmp/claude-out.txt /tmp/prev-out.txt
  build_prompt /tmp/rescue-role.md /tmp/rescue-prompt.txt
  {
    printf '\n## 상황\n\n같은 브랜치의 직전 %s 노드가 실패한 채 끝났어요.\n' "$NODE_NAME"
    printf 'git log 와 git diff 로 상태를 파악하고, 어중간하게 남은 변경을 정리한 뒤\n'
    printf '위 작업을 이어받아 완수해줘.\n\n### 실패한 노드의 마지막 보고\n\n%s\n' \
      "$(tail -c 2000 /tmp/prev-out.txt)"
  } >> /tmp/rescue-prompt.txt
  run_claude /tmp/rescue-prompt.txt
  echo "NODE_LABEL=$NODE_NAME→$RESCUE" >> "$GITHUB_ENV"
else
  echo "NODE_LABEL=$NODE_NAME" >> "$GITHUB_ENV"
fi

echo "CLAUDE_STATUS=$STATUS" >> "$GITHUB_ENV"
