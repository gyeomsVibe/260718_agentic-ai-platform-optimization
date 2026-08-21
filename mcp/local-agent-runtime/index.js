#!/usr/bin/env node
// Local Agent Runtime — 장기 실행 에이전트 세션을 MCP 도구로 노출한다.
//
// 기존 브리지는 위임 1건마다 새 프로세스를 띄웠다. 이 런타임은 프로세스를
// 살려두고 stdin/stdout 스트림을 유지하므로, 오케스트레이터가 같은 세션에
// 여러 턴을 이어서 넣을 수 있다. 대화 맥락이 턴 사이에 보존된다.
//
// 두 CLI 모두 제조사가 제공하는 NDJSON 양방향 프로토콜을 쓴다.
// pexpect 류의 TUI 자동화는 필요 없다. 프로토콜은 2026-08-21 실측으로 확인했다.
//
//   claude : 입력 {"type":"user","message":{"role":"user","content":[{"type":"text","text":...}]}}
//            출력 {"type":"system"|"assistant"|"result", ...}
//   agy    : 입력 {"event":"user","message":{"content":"..."}}
//            출력 {"event":"init"|"step_update"|"result", ...}
//
// 안전 기본값: agy 는 샌드박스 켜짐, 자동승인 꺼짐. 원격 보호는 pre-push 훅이 담당한다.

const { McpServer } = require("@modelcontextprotocol/sdk/server/mcp.js");
const { StdioServerTransport } = require("@modelcontextprotocol/sdk/server/stdio.js");
const { z } = require("zod");
const { spawn } = require("child_process");
const os = require("os");

const MAX_SESSIONS = Number(process.env.LAR_MAX_SESSIONS || "6");
const DEFAULT_TURN_TIMEOUT_MS = Number(process.env.LAR_TURN_TIMEOUT_MS || "180000");
const IDLE_CLOSE_MS = Number(process.env.LAR_IDLE_CLOSE_MS || String(30 * 60 * 1000));
const MAX_EVENTS_KEPT = 400;

const isWindows = process.platform === "win32";
const sessions = new Map();
let seq = 0;

// --- 도구별 어댑터 -------------------------------------------------------

const ADAPTERS = {
  "claude-code": {
    bin: process.env.LAR_CLAUDE_BIN || (isWindows ? "claude.exe" : "claude"),
    args({ model, cwd }) {
      const a = ["--print", "--input-format", "stream-json", "--output-format", "stream-json", "--verbose"];
      if (model) a.push("--model", model);
      return a;
    },
    encode(text) {
      return { type: "user", message: { role: "user", content: [{ type: "text", text: text }] } };
    },
    isTurnEnd(msg) {
      return msg && msg.type === "result";
    },
    // 한 턴에서 사람이 읽을 답변만 뽑는다
    extract(events) {
      const out = [];
      for (const m of events) {
        if (m.type === "assistant") {
          for (const c of (m.message && m.message.content) || []) {
            if (c.type === "text" && c.text) out.push(c.text);
          }
        }
      }
      const last = events[events.length - 1];
      const status = last && last.type === "result" ? (last.is_error ? "ERROR" : "SUCCESS") : "UNKNOWN";
      return { text: out.join("\n").trim(), status };
    },
  },

  antigravity: {
    bin: process.env.LAR_AGY_BIN || (isWindows ? "agy.exe" : "agy"),
    args({ model, printTimeout }) {
      const a = ["--input-format", "stream-json", "--output-format", "stream-json", "--sandbox"];
      if (model) a.push("--model", model);
      a.push("--print-timeout", printTimeout || "180s");
      a.push("-p", "");
      return a;
    },
    encode(text) {
      return { event: "user", message: { content: text } };
    },
    isTurnEnd(msg) {
      return msg && msg.event === "result";
    },
    extract(events) {
      const last = events[events.length - 1];
      if (last && last.event === "result") {
        const r = last.result || {};
        return { text: String(r.response || "").trim(), status: r.status || "UNKNOWN", error: r.error || null };
      }
      return { text: "", status: "UNKNOWN" };
    },
  },
};

// --- 세션 관리 -----------------------------------------------------------

function openSession({ tool, model, cwd, printTimeout }) {
  const adapter = ADAPTERS[tool];
  if (!adapter) throw new Error(`unknown tool "${tool}". use one of: ${Object.keys(ADAPTERS).join(", ")}`);
  if (sessions.size >= MAX_SESSIONS) throw new Error(`session limit reached (${MAX_SESSIONS}). close one first.`);

  const id = `${tool}-${(++seq).toString(36)}${Date.now().toString(36).slice(-4)}`;
  const workdir = cwd || process.cwd();
  const args = adapter.args({ model, cwd: workdir, printTimeout });

  // shell 을 쓰지 않는다. Windows 에서 shell:true 는 인자를 이스케이프 없이 이어붙여
  // 프롬프트에 따옴표나 공백이 있으면 깨진다. 실행 파일이 .exe 라 PATH 조회만으로 충분하다.
  const child = spawn(adapter.bin, args, {
    cwd: workdir,
    stdio: ["pipe", "pipe", "pipe"],
    env: process.env,
  });

  const s = {
    id, tool, adapter, child, cwd: workdir, model: model || null,
    openedAt: Date.now(), lastUsedAt: Date.now(),
    alive: true, exitCode: null,
    buffer: "", events: [], stderr: "",
    turnWaiters: [], turns: 0,
  };

  child.stdout.on("data", (d) => {
    s.buffer += String(d);
    let idx;
    while ((idx = s.buffer.indexOf("\n")) >= 0) {
      const line = s.buffer.slice(0, idx).trim();
      s.buffer = s.buffer.slice(idx + 1);
      if (!line) continue;
      let msg;
      try { msg = JSON.parse(line); } catch { s.events.push({ _raw: line.slice(0, 500) }); continue; }
      s.events.push(msg);
      if (s.events.length > MAX_EVENTS_KEPT) s.events.splice(0, s.events.length - MAX_EVENTS_KEPT);
      if (adapter.isTurnEnd(msg)) {
        const w = s.turnWaiters.shift();
        if (w) w.resolve(msg);
      }
    }
  });

  child.stderr.on("data", (d) => {
    s.stderr = (s.stderr + String(d)).slice(-4000);
  });

  child.on("exit", (code) => {
    s.alive = false;
    s.exitCode = code;
    while (s.turnWaiters.length) {
      const w = s.turnWaiters.shift();
      w.reject(new Error(`session exited with code ${code}. stderr tail: ${s.stderr.slice(-300)}`));
    }
  });

  child.on("error", (err) => {
    s.alive = false;
    while (s.turnWaiters.length) s.turnWaiters.shift().reject(err);
  });

  sessions.set(id, s);
  return s;
}

function sendTurn(s, text, timeoutMs) {
  if (!s.alive) return Promise.reject(new Error(`session ${s.id} is not alive (exit ${s.exitCode})`));
  const startIndex = s.events.length;
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      const i = s.turnWaiters.findIndex((w) => w.timer === timer);
      if (i >= 0) s.turnWaiters.splice(i, 1);
      reject(new Error(`turn timed out after ${timeoutMs}ms. the session is still open; poll agent_read.`));
    }, timeoutMs);

    s.turnWaiters.push({
      timer,
      resolve: () => { clearTimeout(timer); resolve(s.events.slice(startIndex)); },
      reject: (e) => { clearTimeout(timer); reject(e); },
    });

    s.child.stdin.write(JSON.stringify(s.adapter.encode(text)) + "\n", (err) => {
      if (err) {
        clearTimeout(timer);
        reject(err);
      }
    });
    s.lastUsedAt = Date.now();
    s.turns += 1;
  });
}

function closeSession(id) {
  const s = sessions.get(id);
  if (!s) return false;
  try { s.child.stdin.end(); } catch {}
  try { s.child.kill(); } catch {}
  sessions.delete(id);
  return true;
}

setInterval(() => {
  const now = Date.now();
  for (const [id, s] of sessions) {
    if (!s.alive || now - s.lastUsedAt > IDLE_CLOSE_MS) closeSession(id);
  }
}, 60000).unref();

// --- MCP 표면 -----------------------------------------------------------

const server = new McpServer(
  { name: "local-agent-runtime", version: "0.1.0" },
  { capabilities: {} }
);

const ok = (obj) => ({ content: [{ type: "text", text: JSON.stringify(obj, null, 1) }] });
const fail = (e) => ({ content: [{ type: "text", text: JSON.stringify({ ok: false, error: String((e && e.message) || e) }) }] });

server.tool(
  "agent_open",
  "장기 실행 에이전트 세션을 연다. 프로세스가 살아 있으므로 이후 agent_send 로 같은 대화를 이어갈 수 있다. 세션 하나당 대화 맥락 하나.",
  {
    tool: z.enum(["claude-code", "antigravity"]).describe("어느 에이전트를 띄울지"),
    model: z.string().optional().describe("모델 이름. 생략하면 해당 CLI 기본값"),
    cwd: z.string().optional().describe("작업 디렉터리. 생략하면 이 서버의 현재 디렉터리"),
    print_timeout: z.string().optional().describe("antigravity 전용. 예: 180s"),
  },
  async ({ tool, model, cwd, print_timeout }) => {
    try {
      const s = openSession({ tool, model, cwd, printTimeout: print_timeout });
      return ok({ ok: true, session_id: s.id, tool: s.tool, model: s.model, cwd: s.cwd });
    } catch (e) { return fail(e); }
  }
);

server.tool(
  "agent_send",
  "열린 세션에 한 턴을 보내고 그 턴이 끝날 때까지 기다린 뒤 답변을 돌려준다. 같은 세션에 반복 호출하면 맥락이 이어진다.",
  {
    session_id: z.string().describe("agent_open 이 준 세션 ID"),
    message: z.string().describe("보낼 내용"),
    timeout_ms: z.number().optional().describe(`턴 대기 상한. 기본 ${DEFAULT_TURN_TIMEOUT_MS}`),
  },
  async ({ session_id, message, timeout_ms }) => {
    const s = sessions.get(session_id);
    if (!s) return fail(new Error(`no session "${session_id}"`));
    try {
      const events = await sendTurn(s, message, timeout_ms || DEFAULT_TURN_TIMEOUT_MS);
      const r = s.adapter.extract(events);
      return ok({
        ok: true, session_id, turn: s.turns, status: r.status,
        response: r.text, error: r.error || null, event_count: events.length,
      });
    } catch (e) { return fail(e); }
  }
);

server.tool(
  "agent_read",
  "세션이 지금까지 낸 원본 이벤트를 읽는다. 턴이 타임아웃됐거나 중간 진행을 보고 싶을 때 쓴다.",
  {
    session_id: z.string(),
    last: z.number().optional().describe("마지막 N개만. 기본 20"),
  },
  async ({ session_id, last }) => {
    const s = sessions.get(session_id);
    if (!s) return fail(new Error(`no session "${session_id}"`));
    const n = last || 20;
    return ok({
      ok: true, session_id, alive: s.alive, exit_code: s.exitCode, turns: s.turns,
      events: s.events.slice(-n),
      stderr_tail: s.stderr.slice(-500) || null,
    });
  }
);

server.tool(
  "agent_list",
  "열려 있는 세션 목록. 어떤 에이전트가 몇 턴째 살아 있는지 보여준다.",
  {},
  async () => ok({
    ok: true,
    max_sessions: MAX_SESSIONS,
    sessions: [...sessions.values()].map((s) => ({
      session_id: s.id, tool: s.tool, model: s.model, cwd: s.cwd,
      alive: s.alive, turns: s.turns,
      idle_seconds: Math.round((Date.now() - s.lastUsedAt) / 1000),
    })),
  })
);

server.tool(
  "agent_close",
  "세션을 닫고 프로세스를 종료한다. 다 쓴 세션은 닫아야 다른 세션을 열 수 있다.",
  { session_id: z.string() },
  async ({ session_id }) => ok({ ok: closeSession(session_id), session_id })
);

server.tool(
  "runtime_health",
  "런타임 상태와 각 CLI 실행 파일 탐지 결과를 보고한다.",
  {},
  async () => {
    const probe = {};
    for (const [name, a] of Object.entries(ADAPTERS)) probe[name] = a.bin;
    return ok({
      ok: true, platform: process.platform, node: process.version,
      cwd: process.cwd(), tmp: os.tmpdir(),
      open_sessions: sessions.size, max_sessions: MAX_SESSIONS,
      turn_timeout_ms: DEFAULT_TURN_TIMEOUT_MS, idle_close_ms: IDLE_CLOSE_MS,
      binaries: probe,
    });
  }
);

process.on("exit", () => { for (const id of [...sessions.keys()]) closeSession(id); });

const transport = new StdioServerTransport();
server.connect(transport);
