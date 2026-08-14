// 🔒 기능 본체 — 여기에 사용자 설정은 없어요. 그래프 모양은 settings.env 의 CLAUDE_GRAPH 로 바꿔요.
//
// 그래프 펼치기 — CLAUDE_GRAPH 를 단계별 매트릭스(JSON)로 만들어 GITHUB_OUTPUT 에 써요.
// 문법: 'a>b' 순차, 'a+b' 병렬, 'a?b' 는 a 실패 시 b 노드가 수습.
//   예: plan>code?fix>test  ·  api+web>e2e
//
// 출력: s1..s4 (각 단계의 매트릭스 배열). 빈 단계는 [] 라서 워크플로가 건너뛴다.
//   각 항목: { node, label, rescue, make_pr }
//
// GitLab 판과 다른 점 — 수습(?)은 별도 잡이 아니라 노드 잡 안에서 처리한다.
// GitHub Actions 는 잡을 실행 중에 만들어 낼 수 없어서, 수습 잡을 따로 세우려면
// 단계마다 잡을 두 벌씩 선언해야 한다. 같은 브랜치를 이어받아 완수한다는 의미는
// 같은 잡 안에서 이어 돌리는 편이 더 정확하고, 아티팩트로 상태를 주고받을 필요도 없다.

const fs = require("fs");
const path = require("path");

const MAX_STAGES = 4; // 워크플로에 선언해 둔 단계 잡 수 (s1..s4)
const NAME = /^[a-z][a-z0-9_]*$/;
const NODES_DIR = path.join(__dirname, "nodes");

function fail(msg) {
  console.error(`graph: ${msg}`);
  process.exit(1);
}

const graph = (process.env.CLAUDE_GRAPH || "code").trim();
const single = (process.env.CLAUDE_NODE || "").trim(); // 리뷰 fix 루프: 그래프 없이 이 노드 하나만

function parseNode(part) {
  const bits = part.split("?").map((s) => s.trim());
  if (bits.length > 2 || bits.some((b) => !b)) {
    fail(`노드는 '이름' 또는 '이름?수습노드' 꼴이에요: '${part.trim()}'`);
  }
  for (const n of bits) {
    if (!NAME.test(n)) fail(`잘못된 노드 이름 '${n}' (소문자로 시작, 소문자·숫자·_ 만)`);
    if (!fs.existsSync(path.join(NODES_DIR, `${n}.md`))) {
      console.error(`graph: 경고 — .github/agent/nodes/${n}.md 역할 정의가 없어요`);
    }
  }
  return { node: bits[0], rescue: bits[1] || "" };
}

let stages;
if (single) {
  stages = [[parseNode(single)]];
} else {
  stages = graph.split(">").map((stageExpr, i) => {
    if (!stageExpr.trim()) fail(`빈 단계가 있어요 (${i + 1}번째): '${graph}'`);
    return stageExpr.split("+").map(parseNode);
  });
}

if (stages.length > MAX_STAGES) {
  fail(
    `순차 단계는 최대 ${MAX_STAGES}개예요 (지금 ${stages.length}개): '${graph}'\n` +
      `  '+' 로 묶어 병렬로 줄이거나, 작업을 두 번에 나눠 지시하세요.`
  );
}

// 같은 노드가 여러 번 나오면 라벨에 -2, -3 … 을 붙여 진행 화면에서 구분되게 한다
const used = new Map();
function label(node) {
  const n = (used.get(node) || 0) + 1;
  used.set(node, n);
  return n === 1 ? node : `${node}-${n}`;
}

const out = [];
stages.forEach((nodes, i) => {
  const lastStage = i === stages.length - 1;
  out.push(
    nodes.map(({ node, rescue }, j) => ({
      node,
      label: label(node),
      rescue,
      // PR 은 마지막 단계의 마지막 노드 하나만 만든다 — 중간에 열면 완성 전 코드가 리뷰된다
      make_pr: String(lastStage && j === nodes.length - 1),
    }))
  );
});

const lines = [];
for (let i = 0; i < MAX_STAGES; i++) {
  lines.push(`s${i + 1}=${JSON.stringify(out[i] || [])}`);
}

const summary = out
  .map((nodes) => nodes.map((n) => n.label + (n.rescue ? `?${n.rescue}` : "")).join(" + "))
  .join("  →  ");
console.error(`graph: ${summary}`);

const target = process.env.GITHUB_OUTPUT;
if (target) {
  fs.appendFileSync(target, lines.join("\n") + "\n");
} else {
  process.stdout.write(lines.join("\n") + "\n"); // 로컬에서 확인할 때
}
