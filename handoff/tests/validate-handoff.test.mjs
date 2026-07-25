import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { cpSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

import { validateHandoffs } from "../scripts/validate-handoff.mjs";

const testDirectory = dirname(fileURLToPath(import.meta.url));
const sourceRoot = resolve(testDirectory, "../..");
const schemaSource = join(sourceRoot, "handoff", "schemas", "handoff.schema.json");

function git(root, ...argumentsList) {
  return execFileSync("git", argumentsList, { cwd: root, encoding: "utf8" }).trim();
}

function writeHandoff(root, { baseSha, workSha, ownedPaths, status = "HANDOFF_READY" }) {
  const activeDirectory = join(root, "handoff", "active");
  const frontmatter = [
    "---",
    "handoff_id: sample-handoff-001",
    `status: ${status}`,
    "workstream: sample",
    "objective: Verify the handoff contract",
    "repository: owner/repository",
    "branch: main",
    `base_sha: ${baseSha}`,
    `work_sha: ${workSha}`,
    "owned_paths:",
    ...ownedPaths.map((path) => `  - ${path}`),
    "completed:",
    "  - Work commit is available",
    "remaining:",
    "  - Cross-platform pilot",
    "verification:",
    "  - node test passed",
    "decisions:",
    "  - Keep the sample contract minimal",
    "risks:",
    "  - Remote state can change",
    "approvals_required:",
    "  - None for this fixture",
    "next_action: Run the handoff validator",
    "revalidate_when:",
    "  - owned_paths changes after work_sha",
    "---",
    "",
    "# Sample handoff",
    ""
  ].join("\n");

  mkdirSync(activeDirectory, { recursive: true });
  writeFileSync(join(activeDirectory, "sample.md"), frontmatter);
}

function createFixture(t, { ownedPaths = ["src/"], workFiles = { "src/owned.txt": "owned" } } = {}) {
  const parentDirectory = mkdtempSync(join(tmpdir(), "handoff-validation-"));
  const root = join(parentDirectory, "repository");
  const remote = join(parentDirectory, "remote.git");
  mkdirSync(root, { recursive: true });
  mkdirSync(join(root, "handoff", "schemas"), { recursive: true });
  cpSync(schemaSource, join(root, "handoff", "schemas", "handoff.schema.json"));

  git(root, "init", "-b", "main");
  git(root, "config", "user.name", "Handoff Test");
  git(root, "config", "user.email", "handoff@example.test");
  writeFileSync(join(root, "README.md"), "fixture\n");
  git(root, "add", "README.md", "handoff/schemas/handoff.schema.json");
  git(root, "commit", "-m", "test: Add base fixture");
  const baseSha = git(root, "rev-parse", "HEAD");

  git(parentDirectory, "init", "--bare", "remote.git");
  git(root, "remote", "add", "origin", remote);
  git(root, "push", "-u", "origin", "main");

  for (const [path, content] of Object.entries(workFiles)) {
    mkdirSync(dirname(join(root, path)), { recursive: true });
    writeFileSync(join(root, path), `${content}\n`);
  }
  git(root, "add", "src");
  git(root, "commit", "-m", "test: Add work fixture");
  const workSha = git(root, "rev-parse", "HEAD");
  git(root, "push", "origin", "main");

  writeHandoff(root, { baseSha, workSha, ownedPaths });
  git(root, "add", "handoff/active/sample.md");
  git(root, "commit", "-m", "test: Add handoff fixture");
  git(root, "push", "origin", "main");

  t.after(() => rmSync(parentDirectory, { recursive: true, force: true }));
  return { root };
}

test("HANDOFF_READY proves both the work SHA and active record on the remote", (t) => {
  const { root } = createFixture(t);
  const [result] = validateHandoffs({ root, verifyRemote: true, refreshRemote: true });
  assert.deepEqual(result.failures, []);
});

test("remote validation rejects an active record changed only on the local machine", (t) => {
  const { root } = createFixture(t);
  const recordPath = join(root, "handoff", "active", "sample.md");
  writeFileSync(recordPath, `${readFileSync(recordPath, "utf8")}\nLocal-only change.\n`);

  const [result] = validateHandoffs({ root, verifyRemote: true });
  assert.ok(result.failures.includes("active handoff record differs from the remote-tracking branch"));
});

test("contract validation rejects work changes omitted from owned_paths", (t) => {
  const { root } = createFixture(t, {
    ownedPaths: ["src/owned.txt"],
    workFiles: {
      "src/owned.txt": "owned",
      "src/unlisted.txt": "unlisted"
    }
  });

  const [result] = validateHandoffs({ root });
  assert.ok(result.failures.includes("work change is outside owned_paths: src/unlisted.txt"));
});

test("STALE records preserve changed owned paths without claiming readiness", (t) => {
  const { root } = createFixture(t);
  const recordPath = join(root, "handoff", "active", "sample.md");
  writeFileSync(recordPath, readFileSync(recordPath, "utf8").replace("status: HANDOFF_READY", "status: STALE"));
  writeFileSync(join(root, "src", "owned.txt"), "changed after work SHA\n");

  const [result] = validateHandoffs({ root });
  assert.deepEqual(result.failures, []);
});

test("contract validation rejects forbidden content like Windows absolute paths or secrets", (t) => {
  const { root } = createFixture(t);
  const recordPath = join(root, "handoff", "active", "sample.md");
  writeFileSync(recordPath, `${readFileSync(recordPath, "utf8")}\nForbidden path: C:\\Users\\test\n`);
  git(root, "add", "handoff/active/sample.md");
  git(root, "commit", "-m", "test: Add forbidden path");
  git(root, "push", "origin", "main");

  const [result] = validateHandoffs({ root, verifyRemote: true });
  assert.ok(result.failures.some(f => f.includes("forbidden content")));
});
