export const meta = {
  name: 'work',
  description: '계획을 단계별로 돌려 코드를 만든다 — 노드 역할을 서브에이전트로 부른다',
  whenToUse: '이슈나 스펙 하나를 로컬에서 끝까지 진행할 때. args 로 계획과 작업 지시를 준다.',
  phases: [{ title: '계획 확인' }, { title: '구현' }, { title: '검증' }],
}

// 로컬 오케스트레이션 — GitHub Actions 를 건너다니던 루프를 세션 하나 안에서 돌린다.
//
// 왜 이게 되나: 여기는 사람 컴퓨터라 세션이 이어진다. Actions 에서는 잡마다 프로세스가
// 죽어서 graph.js·plan-stage.sh·next-role.sh·state.sh 로 상태를 넘겨야 했다.
// 세션 하나면 그 넷이 필요 없다 — pipeline 과 변수가 그 일을 한다.
//
// 역할은 .claude/agents/ 의 서브에이전트다. 원본은 .github/agent/nodes/ 이고
// launcher 가 복사한다. tools 를 Claude Code 가 강제하므로 split 은 셸을 못 쓴다.
//
// args:
//   { plan: 'plan>api+web>e2e', task: '<작업 지시 또는 specs/ 경로>' }
//   plan 을 안 주면 code 하나만 돈다 (settings.env 의 CLAUDE_GRAPH 기본값과 같다).

const plan = (args && args.plan) || 'code'
const task = (args && args.task) || ''

if (!task) {
  log('args.task 가 없다 — 무엇을 만들지 알 수 없으므로 멈춘다')
  return { stages: [], note: 'args.task 없음' }
}

// 'plan>api+web>e2e' → [['plan'], ['api','web'], ['e2e']]
// graph.js 와 같은 문법이다. 수습(?)은 여기서 다루지 않는다 —
// 실패하면 그 자리에서 사람이 보고 있으므로 자동 수습이 필요 없다.
const stages = plan.split('>').map((s) => s.split('+').map((n) => n.trim()).filter(Boolean))

phase('계획 확인')
log(`계획: ${stages.map((s) => s.join(' + ')).join('  →  ')}`)

const BRIEF = `## 작업

${task}

작업이 끝나면 변경을 논리 단위로 나눠 직접 git add / git commit 해줘.
리팩터링과 기능 변경은 같은 커밋에 섞지 말고, 메시지는 <type>:<제목> 형식으로
(type 소문자, 콜론 뒤 공백 없음: feat/fix/refactor/test/docs/chore 등).
최종 결과 보고는 한국어로 쓴다. 코드·식별자·경로는 원문 그대로 둔다.`

const REPORT = {
  type: 'object',
  properties: {
    done: { type: 'string', description: '무엇을 했는지 한두 문장' },
    files: { type: 'array', items: { type: 'string' }, description: '고친 파일 경로' },
    checks: { type: 'string', description: '돌린 검증 명령과 결과. 안 돌렸으면 그렇게 적는다' },
    blocked: { type: 'string', description: '못 한 것과 이유. 없으면 빈 문자열' },
  },
  required: ['done', 'files', 'checks', 'blocked'],
}

// 단계는 순서를 지켜야 한다 — api 가 CONTRACT.md 를 적어야 web 이 그걸 보고 만든다.
// 그래서 pipeline 이 아니라 단계마다 barrier 다. 한 단계 안에서는 나란히 돈다.
const results = []
for (let i = 0; i < stages.length; i++) {
  const roles = stages[i]
  const last = i === stages.length - 1
  phase(last ? '검증' : '구현')

  const done = await parallel(
    roles.map((role) => () =>
      agent(BRIEF, {
        agentType: role,
        label: `${role} (${i + 1}/${stages.length})`,
        phase: last ? '검증' : '구현',
        schema: REPORT,
      }),
    ),
  )

  const ok = done.filter(Boolean)
  results.push({ stage: i + 1, roles, reports: ok })

  const blocked = ok.filter((r) => r.blocked)
  if (blocked.length) {
    log(`단계 ${i + 1} 에서 막힌 것이 있다 — 다음 단계로 넘어가지 않는다`)
    blocked.forEach((r) => log(`  ${r.blocked}`))
    return { stages: results, stopped: `단계 ${i + 1}` }
  }
  if (ok.length < roles.length) {
    log(`단계 ${i + 1} 의 역할 ${roles.length - ok.length}개가 답을 못 냈다 — 멈춘다`)
    return { stages: results, stopped: `단계 ${i + 1} 응답 없음` }
  }
}

return { stages: results }
