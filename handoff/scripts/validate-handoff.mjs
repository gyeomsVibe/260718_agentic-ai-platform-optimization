import { execFileSync } from "node:child_process";
import { readdirSync, readFileSync } from "node:fs";
import { dirname, isAbsolute, join, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const scriptDirectory = dirname(fileURLToPath(import.meta.url));
const repositoryRoot = resolve(scriptDirectory, "../..");
const activeDirectory = join(repositoryRoot, "handoff", "active");
const schemaPath = join(repositoryRoot, "handoff", "schemas", "handoff.schema.json");
const schema = JSON.parse(readFileSync(schemaPath, "utf8"));
const forbiddenContent = [
  ["Windows absolute path", /\b[A-Za-z]:[\\/]/],
  ["user home path", /(?:^|[\\/])Users[\\/]/i],
  ["private key marker", /-----BEGIN [A-Z ]*PRIVATE KEY-----/],
  ["GitHub token shape", /\b(?:ghp_|github_pat_)[A-Za-z0-9_]{20,}\b/],
  ["API key shape", /\bsk-[A-Za-z0-9_-]{20,}\b/]
];
const remoteRequiredStatuses = new Set(["HANDOFF_READY", "CLAIMED"]);

function runGit(argumentsList, root = repositoryRoot) {
  try {
    execFileSync("git", argumentsList, {
      cwd: root,
      stdio: "ignore"
    });
    return true;
  } catch {
    return false;
  }
}

function readGit(argumentsList, root = repositoryRoot) {
  try {
    return execFileSync("git", argumentsList, {
      cwd: root,
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"]
    }).trim();
  } catch {
    return null;
  }
}

function parseFrontmatter(source) {
  const lines = source.replaceAll("\r\n", "\n").split("\n");
  if (lines[0] !== "---") {
    throw new Error("frontmatter must start on line 1");
  }

  const closingIndex = lines.indexOf("---", 1);
  if (closingIndex < 0) {
    throw new Error("frontmatter closing delimiter is missing");
  }

  const metadata = {};
  let listKey = null;
  for (const line of lines.slice(1, closingIndex)) {
    if (!line.trim()) continue;

    const listItem = line.match(/^  - (.+)$/);
    if (listItem && listKey) {
      metadata[listKey].push(listItem[1].trim());
      continue;
    }

    const field = line.match(/^([a-z_]+):(?:\s*(.*))?$/);
    if (!field) throw new Error(`unsupported frontmatter line: ${line}`);

    const [, key, value] = field;
    if (Object.hasOwn(metadata, key)) throw new Error(`duplicate field: ${key}`);

    if (value) {
      metadata[key] = value.trim();
      listKey = null;
    } else {
      metadata[key] = [];
      listKey = key;
    }
  }

  return metadata;
}

function validateContract(metadata, source) {
  const failures = [];
  const allowedKeys = new Set(Object.keys(schema.properties));

  for (const key of schema.required) {
    if (!Object.hasOwn(metadata, key)) failures.push(`missing required field: ${key}`);
  }

  for (const [key, value] of Object.entries(metadata)) {
    const definition = schema.properties[key];
    if (!allowedKeys.has(key)) {
      failures.push(`unknown field: ${key}`);
      continue;
    }

    const resolved = definition.$ref ? schema.$defs.nonEmptyStringArray : definition;
    if (resolved.type === "array") {
      if (!Array.isArray(value) || value.length < 1 || value.some((item) => !item)) {
        failures.push(`${key} must contain at least one item`);
      }
      continue;
    }

    if (typeof value !== "string" || value.length < (resolved.minLength ?? 0)) {
      failures.push(`${key} must be a non-empty string`);
      continue;
    }

    if (resolved.pattern && !new RegExp(resolved.pattern).test(value)) {
      failures.push(`${key} has an invalid format`);
    }

    if (resolved.enum && !resolved.enum.includes(value)) {
      failures.push(`${key} has an unsupported value`);
    }
  }

  for (const [label, pattern] of forbiddenContent) {
    if (pattern.test(source)) failures.push(`forbidden content: ${label}`);
  }

  const completed = new Set(metadata.completed ?? []);
  const contradictions = (metadata.remaining ?? []).filter((item) => completed.has(item));
  if (contradictions.length > 0) failures.push("completed and remaining overlap");

  return failures;
}

function normalizeRepositoryPath(value) {
  return value.replaceAll("\\", "/").replace(/^\.\//, "").replace(/\/+$/, "");
}

function ownsPath(ownedPath, changedPath) {
  const normalizedOwnedPath = normalizeRepositoryPath(ownedPath);
  const normalizedChangedPath = normalizeRepositoryPath(changedPath);
  return normalizedChangedPath === normalizedOwnedPath ||
    normalizedChangedPath.startsWith(`${normalizedOwnedPath}/`);
}

function validateGitEvidence(metadata, root) {
  const failures = [];
  const ownedPaths = metadata.owned_paths ?? [];

  for (const ownedPath of ownedPaths) {
    if (isAbsolute(ownedPath) || ownedPath.includes("..") || ownedPath.includes("\\")) {
      failures.push(`owned path must be repository-relative: ${ownedPath}`);
    }
  }

  if (!runGit(["cat-file", "-e", `${metadata.base_sha}^{commit}`], root)) {
    failures.push("base_sha is not a local commit");
  }
  if (!runGit(["cat-file", "-e", `${metadata.work_sha}^{commit}`], root)) {
    failures.push("work_sha is not a local commit");
    return failures;
  }
  if (!runGit(["merge-base", "--is-ancestor", metadata.base_sha, metadata.work_sha], root)) {
    failures.push("base_sha is not an ancestor of work_sha");
  }
  if (!runGit(["merge-base", "--is-ancestor", metadata.work_sha, "HEAD"], root)) {
    failures.push("work_sha is not an ancestor of HEAD");
  }
  if (remoteRequiredStatuses.has(metadata.status) &&
      !runGit(["merge-base", "--is-ancestor", metadata.work_sha, `origin/${metadata.branch}`], root)) {
    failures.push("work_sha is not present on the remote-tracking branch");
  }

  const workChanges = readGit(
    ["diff", "--name-only", metadata.base_sha, metadata.work_sha],
    root
  );
  if (workChanges === null) {
    failures.push("cannot inspect changes between base_sha and work_sha");
  } else {
    for (const changedPath of workChanges.split("\n").filter(Boolean)) {
      if (!ownedPaths.some((ownedPath) => ownsPath(ownedPath, changedPath))) {
        failures.push(`work change is outside owned_paths: ${changedPath}`);
      }
    }
  }

  for (const ownedPath of ownedPaths) {
    if (remoteRequiredStatuses.has(metadata.status) &&
        !runGit(["diff", "--quiet", metadata.work_sha, "--", ownedPath], root)) {
      failures.push(`owned path changed after work_sha: ${ownedPath}`);
    }
  }

  return failures;
}

function validateRemoteRecord(path, metadata, root) {
  if (!remoteRequiredStatuses.has(metadata.status)) return [];

  const failures = [];
  const remoteRef = `origin/${metadata.branch}`;
  const relativePath = normalizeRepositoryPath(relative(root, path));
  const remoteBlob = readGit(["rev-parse", `${remoteRef}:${relativePath}`], root);
  const localBlob = readGit(["hash-object", relativePath], root);

  if (remoteBlob === null) {
    failures.push("active handoff record is not present on the remote-tracking branch");
  } else if (localBlob === null || remoteBlob !== localBlob) {
    failures.push("active handoff record differs from the remote-tracking branch");
  }

  return failures;
}

function validateRestart(metadata) {
  const failures = [];
  const restartFields = [
    "repository",
    "branch",
    "work_sha",
    "owned_paths",
    "verification",
    "next_action",
    "revalidate_when"
  ];

  for (const key of restartFields) {
    const value = metadata[key];
    if (!value || (Array.isArray(value) && value.length < 1)) {
      failures.push(`restart simulation cannot resolve: ${key}`);
    }
  }

  return failures;
}

export function validateHandoffs({
  root = repositoryRoot,
  verifyRemote = false,
  refreshRemote = false
} = {}) {
  const activePath = join(root, "handoff", "active");
  const files = readdirSync(activePath).filter((file) => file.endsWith(".md"));
  const results = [];

  for (const file of files) {
    const path = join(activePath, file);
    const source = readFileSync(path, "utf8");
    let metadata;

    try {
      metadata = parseFrontmatter(source);
    } catch (error) {
      results.push({ file, failures: [error.message] });
      continue;
    }

    const failures = [
      ...validateContract(metadata, source),
      ...validateGitEvidence(metadata, root),
      ...validateRestart(metadata)
    ];

    if (verifyRemote && remoteRequiredStatuses.has(metadata.status)) {
      if (refreshRemote && !runGit(["fetch", "origin", metadata.branch], root)) {
        failures.push("cannot refresh the remote-tracking branch");
      }
      failures.push(...validateRemoteRecord(path, metadata, root));
    }

    results.push({ file, failures });
  }

  return results;
}

function main() {
  const verifyRemote = process.argv.includes("--verify-remote");
  const results = validateHandoffs({ verifyRemote, refreshRemote: verifyRemote });
  const failureCount = results.reduce((count, result) => count + result.failures.length, 0);

  for (const result of results) {
    if (result.failures.length === 0) {
      console.log(`handoff/active/${result.file}: PASS`);
      continue;
    }
    for (const failure of result.failures) {
      console.error(`handoff/active/${result.file}: ${failure}`);
    }
  }

  if (failureCount > 0) process.exitCode = 1;
  else console.log(`Validated ${results.length} active handoff record(s).`);
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) main();
