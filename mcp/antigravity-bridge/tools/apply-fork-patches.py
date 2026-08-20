#!/usr/bin/env python3
"""Re-apply this repository's fork patches to a fresh upstream index.js.

Upstream:  https://github.com/TurkerYakup/mcp-server-google-antigravity
Baseline:  1.0.2, sha256 84c9dd1ba716678598c9510a4a76f1f0bb5030fc233fa9220ffcb1b79db1b360

Usage:
    python apply-fork-patches.py <upstream-index.js> <output-index.js>

Every step asserts on the exact text it expects, so an upstream change that
moves or rewrites a patched region fails loudly instead of silently producing
a half-patched file. When that happens, re-read the upstream diff, update the
line ranges and strings here, and record the new hashes in ../SOURCE.md.

Rationale for each patch: ../../../agent-swarm/audits/2026-08-21_mcp-server-google-antigravity.md
"""

import hashlib
import io
import sys

UPSTREAM_SHA256 = "84c9dd1ba716678598c9510a4a76f1f0bb5030fc233fa9220ffcb1b79db1b360"

# 1-indexed, inclusive line ranges to delete, in the upstream numbering.
# Applied in descending order so earlier ranges keep their numbering.
DELETIONS = [
    (883, 900, "antigravity_read_file (H2: unconfined arbitrary path read)"),
    (806, 863, "antigravity_create_folder / create_file / buildTree / create_tree / list_dir (H2)"),
    (552, 563, "write_to_file output mirroring block (H2)"),
]

CHILD_ENV_HELPER = '''
// FORK: hand the child only what agy needs, instead of the entire parent environment.
// Upstream passed `env: process.env`, so any credential held by the orchestrator
// process was inherited by every delegated job.
const CHILD_ENV_ALLOW = new Set([
  "PATH", "PATHEXT", "SYSTEMROOT", "SYSTEMDRIVE", "WINDIR", "COMSPEC",
  "TEMP", "TMP", "TMPDIR", "HOME", "USERPROFILE", "HOMEDRIVE", "HOMEPATH",
  "APPDATA", "LOCALAPPDATA", "PROGRAMDATA", "PROGRAMFILES", "PROGRAMFILES(X86)",
  "USERNAME", "USER", "LOGNAME", "SHELL", "LANG", "LC_ALL",
  "NUMBER_OF_PROCESSORS", "PROCESSOR_ARCHITECTURE", "OS",
]);
const CHILD_ENV_PREFIXES = ["AGY_", "GOOGLE_", "GEMINI_"];
function childEnv() {
  const out = {};
  for (const k of Object.keys(process.env)) {
    const K = k.toUpperCase();
    if (CHILD_ENV_ALLOW.has(K) || CHILD_ENV_PREFIXES.some((p) => K.startsWith(p))) out[k] = process.env[k];
  }
  return out;
}'''

HEADER = """// Vendored fork of mcp-server-google-antigravity@1.0.2
// Upstream: https://github.com/TurkerYakup/mcp-server-google-antigravity (MIT, Turker Yakup)
// Fork rationale, upstream hash and full change list: ./SOURCE.md
// Do not edit to track upstream; re-apply the documented patches instead.
"""

REPLACEMENTS = [
    (
        'const DEFAULT_AUTO_APPROVE = String(process.env.AGY_AUTO_APPROVE || "true").toLowerCase() !== "false";',
        'const DEFAULT_AUTO_APPROVE = false; // FORK: hardcoded off. Upstream defaulted to true, which maps to\n'
        '                                    // --dangerously-skip-permissions. Per-call auto_approve:true still works,\n'
        '                                    // but it must now be an explicit, visible choice. AGY_AUTO_APPROVE is ignored.',
        "H1: DEFAULT_AUTO_APPROVE -> false",
    ),
    (
        'const DEFAULT_SANDBOX = String(process.env.AGY_SANDBOX || "false").toLowerCase() === "true";',
        'const DEFAULT_SANDBOX = String(process.env.AGY_SANDBOX || "true").toLowerCase() === "true"; // FORK: default true',
        "DEFAULT_SANDBOX -> true",
    ),
    (
        'const MODEL_CACHE_TTL_MS = Number(process.env.AGY_MODEL_TTL_MS || "300000");',
        'const MODEL_CACHE_TTL_MS = Number(process.env.AGY_MODEL_TTL_MS || "300000");\n' + CHILD_ENV_HELPER,
        "H3: childEnv() helper inserted",
    ),
    (
        'const proc = pty.spawn(AGY_BIN, args, { name: "xterm-color", cols: PTY_COLS, rows: PTY_ROWS, env: process.env });',
        'const proc = pty.spawn(AGY_BIN, args, { name: "xterm-color", cols: PTY_COLS, rows: PTY_ROWS, env: childEnv() }); // FORK',
        "H3: pty.spawn env -> childEnv()",
    ),
    (
        'const proc = spawn(AGY_BIN, args, { stdio: ["ignore", "pipe", "pipe"] });',
        'const proc = spawn(AGY_BIN, args, { stdio: ["ignore", "pipe", "pipe"], env: childEnv() }); // FORK',
        "H3: spawn env -> childEnv()",
    ),
    (
        '    write_to_file: z.string().optional().describe("Absolute output file path for final answer mirroring"),\n',
        '',
        "H2: write_to_file schema removed",
    ),
    (
        'async ({ prompt, thinking_depth, add_dirs, auto_approve, new_project, model, mode, agent, project, sandbox, print_timeout, write_to_file, extract }) => {',
        'async ({ prompt, thinking_depth, add_dirs, auto_approve, new_project, model, mode, agent, project, sandbox, print_timeout, extract }) => {',
        "H2: write_to_file destructure removed",
    ),
    (
        '        writeToFile: write_to_file,\n',
        '',
        "H2: writeToFile passthrough removed",
    ),
    (
        'const server = new McpServer({ name: "antigravity", version: "1.0.2" }, { capabilities: { logging: {} } });',
        'const server = new McpServer({ name: "antigravity-bridge-fork", version: "1.0.2-fork.1" }, { capabilities: { logging: {} } });',
        "server identity marked as fork",
    ),
]


def main(src, dst):
    raw = io.open(src, encoding="utf-8", newline="").read()
    digest = hashlib.sha256(raw.encode("utf-8")).hexdigest()
    print("upstream sha256:", digest)
    if digest != UPSTREAM_SHA256:
        print("WARNING: upstream differs from the recorded baseline.")
        print("         Verify every patch below before trusting the result.")

    lines = raw.split("\n")
    print("upstream lines:", len(lines))

    for start, end, label in DELETIONS:
        del lines[start - 1:end]
        print("deleted %d-%d  %s" % (start, end, label))

    text = "\n".join(lines)

    for old, new, label in REPLACEMENTS:
        found = text.count(old)
        assert found == 1, "expected exactly 1 occurrence for %r, found %d" % (label, found)
        text = text.replace(old, new)
        print("patched:", label)

    # the shebang must stay on line 1, so the provenance header goes beneath it
    head, rest = text.split("\n", 1)
    assert head.startswith("#!"), "expected a shebang on line 1, found: %r" % head[:40]
    text = head + "\n" + HEADER + rest

    io.open(dst, "w", encoding="utf-8", newline="\n").write(text)
    print("---")
    print("wrote:", dst)
    print("fork lines:", len(text.split("\n")))
    print("fork sha256:", hashlib.sha256(text.encode("utf-8")).hexdigest())


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(2)
    main(sys.argv[1], sys.argv[2])
