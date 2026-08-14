// 🔒 기능 본체 — 일꾼·리뷰어 로그 정리기.
//   스트림 요약: `claude ... | node stream.js`
//   최종 답변 추출: `node stream.js result < stream.jsonl`
//
// 워크플로는 기본 브랜치에서 이 파일을 꺼내 /tmp 로 복사해 쓴다 — 작업 브랜치에
// 파일이 없거나 에이전트가 이 파일을 고쳐도 그 잡의 로그 처리가 깨지지 않게.

const fs = require("fs");

const trunc = (s, n = 70) => {
  s = String(s).replace(/\s+/g, " ").trim();
  return s.length > n ? s.slice(0, n) + "…" : s;
};

if (process.argv[2] === "result") {
  let out = "";
  try {
    const lines = fs.readFileSync(process.argv[3] || "/tmp/claude-stream.jsonl", "utf8").trim().split("\n");
    for (let i = lines.length - 1; i >= 0; i--) {
      try {
        const j = JSON.parse(lines[i]);
        if (j.type === "result") {
          out = j.result || "";
          break;
        }
      } catch (e) {}
    }
  } catch (e) {}
  process.stdout.write(out || "(결과 텍스트 없음 — 실행 로그의 스트림 참조)");
} else {
  require("readline")
    .createInterface({ input: process.stdin })
    .on("line", (line) => {
      try {
        const j = JSON.parse(line);
        if (j.type === "assistant") {
          for (const c of (j.message && j.message.content) || []) {
            if (c.type === "tool_use") {
              const i = c.input || {};
              const t = i.file_path || i.path || i.command || i.pattern || i.description || "";
              console.log("→ " + c.name + (t ? "  " + trunc(t) : ""));
            } else if (c.type === "text" && c.text && c.text.trim()) {
              console.log("💬 " + trunc(c.text, 90));
            }
          }
        } else if (j.type === "user") {
          for (const c of (j.message && j.message.content) || []) {
            if (c.type === "tool_result" && c.is_error) {
              console.log("⚠ 도구 오류  " + trunc(typeof c.content === "string" ? c.content : JSON.stringify(c.content)));
            }
          }
        } else if (j.type === "result") {
          console.log("✅ 완료" + (j.num_turns ? "  (턴 " + j.num_turns + ")" : ""));
        }
      } catch (e) {}
    });
}
