---
name: harness-loop
description: >-
  구현 → 리뷰 → 수정을 판정이 날 때까지 반복한다. CI 의 리뷰 루프를 지금 작업 트리에서 돌리는 절차다.
  "루프로 돌려줘", "통과할 때까지", "리뷰 받고 고쳐줘", "리뷰어에게 검토시켜줘" 같은 요청에 사용한다.
  상한·통과 기준·판정 어휘는 CI 설정에서 읽어 CI 와 같은 기준으로 판정한다.
  단계로 나눠 만들어야 하면 harness-graph 를 먼저 쓴다 — 그쪽이 제작을 끝낸 뒤 이 절차를 부른다.
argument-hint: "[api|web|code] <작업 지시>"
disable-model-invocation: true
allowed-tools: Bash(git add:*) Bash(git status:*) Bash(git diff:*) Bash(cd backend && ./gradlew:*) Bash(cd frontend && npm:*) Bash(.github/agent/next-role.sh:*)
---

# 리뷰 루프

`$ARGUMENTS` 의 첫 낱말이 `api`·`web`·`code` 중 하나면 그것이 담당 노드이고, 나머지가 작업 지시다.

노드가 없으면 담당자를 **직전 라운드의 diff 가 정한다** — 백엔드만 고쳤으면 `api`, 프론트만이면 `web`, 양쪽이거나 공통 파일이면 `code` 다.

재작업 라운드는 `fix` 노드가 맡는다 — 지적만 고치는 자리다.

## 시작 전에

작업 시작 시 기존 변경과 기준점을 기록한다. 기존 변경이 있으면 보존한 별도 복사본·스냅샷에서 작업하여 이번 변경과 구분한다. 기존 변경을 지우거나 대신 커밋하지 않는다.

그래프에서 이어받거나 같은 작업을 재개할 때는 기록된 시작 기준점과 노드 산출물을 사용한다. 제작 결과가 있다는 이유로 다시 clean 상태를 요구하지 않는다. 기준점을 복원할 근거가 없으면 멈춘다.

기록할 디렉터리를 정한다: `.claude/state/loop/<이름>/` (이름은 사용자가 주지 않으면 `YYYYmmdd-HHMMSS`).

상한은 `.github/agent/settings.env` 의 `CLAUDE_MAX_ROUNDS`·`CLAUDE_MAX_STEPS` 를 읽어 쓴다. **여기 숫자를 적지 않는다.**

## 한 라운드

1. **구현** — 담당 노드의 서브에이전트에게 작업을 맡긴다. 2라운드부터는 `fix` 로 바꿔 **직전 리뷰의 차단 지적만** 고치게 하고, 지적 외의 리팩터링을 곁들이지 말라고 명시한다.

2. **변경 수집** — 기록한 작업 시작 기준점부터의 전체 리뷰 diff 와 직전 라운드 스냅샷 이후의 수정 diff 를 따로 보존한다. 격리된 작업 트리에서만 작업 파일을 stage 한다.

   수정 라운드에서 직전 결과와 파일 내용이 같으면 누적 diff 가 남아 있어도 더 돌리지 않는다 — 아무것도 바꾸지 않은 것이다. 그래프 직후 첫 리뷰는 제작 결과와 시작 기준점을 비교한다.

   diff 가 `CLAUDE_DIFF_LIMIT_BYTES` 를 넘으면 잘린다. 그때는 개별 지적 대신 **PR 을 쪼개는 것**이 답이다.

3. **영역 판정** — diff 의 `^+++ b/backend/`·`^+++ b/frontend/` 로 `backend`·`frontend`·`all`·`common` 중 하나를 정한다. 줄 머리로 봐야 첫 줄을 놓치지 않는다.

4. **기계 검사** — 영역에 따라 실행하고 **돌았는지와 통과했는지를 구분해** 기록한다.

   - 백엔드가 걸리면 `cd backend && ./gradlew ktlintCheck unitTest`. ktlint 가 실패하면 `./gradlew ktlintFormat` 후 다시 확인한다.

   - 프론트가 걸리면 `cd frontend && npm ci && npm run build`. `frontend/node_modules` 가 없으면 **실행 불가**이지 통과가 아니다.

   - 계층·스타일은 `bin/layer-check`·`bin/style-check` 가 센다. 검사한 **파일 수**를 함께 기록한다.

   **`BUILD SUCCESSFUL` 은 통과 기록이 아니다.** Gradle 은 캐시로 태스크를 건너뛰고도 성공이라고 말한다 —
   `build/test-results/` 의 XML 을 세어 **실계수**를 남긴다. 리팩터링 라운드면 이전 실계수와 같아야 한다.

   빌드 통과는 기능 검증을 대체하지 않는다. 작업 시작 시 영역 README 와 변경 요구에 맞는 필수 검사 이름을 고정하고, 명령·종료 코드·원출력을 보존한다.

5. **리뷰** — 리뷰어 서브에이전트에게 맡긴다. 작업 지시·기계 검사 결과·`rules/code-review.md`·diff 를 전달한다.

   판정 어휘와 출력 형식은 `.github/agent/review-role.md` 가 정한다 — 그 파일을 그대로 전달하고 여기에 옮겨 적지 않는다. 판정은 **`PASS` · `CHANGES_REQUESTED` 둘뿐**이다.

   통과 기준은 `settings.env` 의 `CLAUDE_REVIEW_BAR` 를 읽어 함께 전달한다.

   리뷰어에게는 쓰기 도구를 주지 않는다.

6. **기록** — 라운드마다 `round-N-worker.md`·`round-N.patch`(전체)·`round-N-delta.patch`(이번 수정)·`round-N-review.md` 와 검사 원출력을 남긴다.

   E2E 를 돌렸으면 결과 JSON·로그·캡처 경로를 보존한다 (**frontend-e2e**).

## 다음에 무엇을 돌릴지 — 스크립트가 정한다

**전이 규칙을 이 문서에 다시 적지 않는다.** `.github/agent/next-role.sh` 가 정본이고, CI 와 같은 답을 내야 하므로 그것을 그대로 부른다.

```bash
VERDICT=<PASS|CHANGES_REQUESTED> ROUNDS=<n> MAX_ROUNDS=<설정값> \
STEP=<n> MAX_STEPS=<설정값> HAS_PAT=<true|false> \
  .github/agent/next-role.sh
```

stdout 한 줄이 답이다 — `done`(더 부를 역할 없음) · `human`(사람을 부른다) · `loop-off`(PAT 이 없어 루프가 꺼짐) · `<역할 이름들>`.

**왜 그렇게 정했는지는 stderr 한 줄로 나온다.** 그 줄을 사용자 보고에 그대로 싣는다 — 이유를 짐작해 지어내지 않는다.

머지 여부는 별개다. `.github/agent/loop-decision.sh` 가 `merge`·`human-merge`·`no-merge` 중 하나를 낸다. 로컬 루프는 **커밋도 머지도 하지 않으므로** 이 판단을 참고만 한다.

### 스크립트보다 앞서는 것 하나

**기계 검사가 돌지 못했으면 판정 이전에 멈춘다.** 검사 미실행은 통과가 아니다.

실행한 검사가 실패하면 리뷰어가 `PASS` 를 내도 통과로 적지 않는다. 검사 이름을 차단 식별자로 남겨 다음 라운드의 수정 대상으로 삼는다.

### 같은 지적이 반복되면

직전 라운드와 **같은 차단 지적**이 또 나오면(`파일:라인` 으로 비교) 더 돌려도 소용없다. 멈추기 **전에** 원인 진단을 `advice.md` 에 남긴다 — 구현자가 무엇을 놓쳤는지, 지적이 틀린 것인지, 요청과 규칙이 충돌하는 것인지. 고치지는 않는다.

## 끝나면

`state.json` 에 작업·노드·상한·상태와 라운드별 기록(담당자·변경 파일 수·판정·차단 수·참고 수·기계 검사·테스트 실계수)을 남긴다.

**커밋하지 않는다.** 변경은 작업 트리에 남기고 사람이 확인해 커밋한다. 마지막에 멈춘 이유와 사람이 볼 것을 한 줄로 알린다.

## 하지 않는 것

- 상한·통과 기준·판정 어휘·전이 규칙을 이 문서에 적지 않는다 — 원본은 `settings.env`·`review-role.md`·`next-role.sh` 다.

- 라운드 수를 자기 기억으로 세지 않는다. 기록한 라운드 파일이 원본이다.

- 구현 노드에게 재위임시키지 않는다. 영역 밖 변경이 필요하면 담당자를 바꾼다.

- 실행하지 않은 검증을 통과로 적지 않는다.
