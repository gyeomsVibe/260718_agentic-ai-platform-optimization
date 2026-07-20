import { execFileSync } from "node:child_process";
import { readdirSync, readFileSync } from "node:fs";
import { dirname, isAbsolute, join, resolve } from "node:path";
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

function runGit(argumentsList) {
  try {
    execFileSync("git", argumentsList, {
      cwd: repositoryRoot,
      stdio: "ignore"
    });
    return true;
  } catch {
    return false;
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

function validateGitEvidence(metadata) {
  const failures = [];
  const ownedPaths = metadata.owned_paths ?? [];

  for (const ownedPath of ownedPaths) {
    if (isAbsolute(ownedPath) || ownedPath.includes("..") || ownedPath.includes("\\")) {
      failures.push(`owned path must be repository-relative: ${ownedPath}`);
    }
  }

  if (!runGit(["cat-file", "-e", `${metadata.base_sha}^{commit}`])) {
    failures.push("base_sha is not a local commit");
  }
  if (!runGit(["cat-file", "-e", `${metadata.work_sha}^{commit}`])) {
    failures.push("work_sha is not a local commit");
    return failures;
  }
  if (!runGit(["merge-base", "--is-ancestor", metadata.base_sha, metadata.work_sha])) {
    failures.push("base_sha is not an ancestor of work_sha");
  }
  if (!runGit(["merge-base", "--is-ancestor", metadata.work_sha, "HEAD"])) {
    failures.push("work_sha is not an ancestor of HEAD");
  }
  if (metadata.status === "HANDOFF_READY" &&
      !runGit(["merge-base", "--is-ancestor", metadata.work_sha, `origin/${metadata.branch}`])) {
    failures.push("work_sha is not present on the remote-tracking branch");
  }

  for (const ownedPath of ownedPaths) {
    if (!runGit(["diff", "--quiet", metadata.work_sha, "--", ownedPath])) {
      failures.push(`owned path changed after work_sha: ${ownedPath}`);
    }
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

const files = readdirSync(activeDirectory).filter((file) => file.endsWith(".md"));
let failureCount = 0;

for (const file of files) {
  const path = join(activeDirectory, file);
  const source = readFileSync(path, "utf8");
  let metadata;

  try {
    metadata = parseFrontmatter(source);
  } catch (error) {
    console.error(`handoff/active/${file}: ${error.message}`);
    failureCount += 1;
    continue;
  }

  const passOne = [
    ...validateContract(metadata, source),
    ...validateGitEvidence(metadata)
  ];
  const passTwo = validateRestart(metadata);
  const failures = [...passOne, ...passTwo];

  if (failures.length === 0) {
    console.log(`handoff/active/${file}: PASS`);
    continue;
  }

  failureCount += failures.length;
  for (const failure of failures) {
    console.error(`handoff/active/${file}: ${failure}`);
  }
}

if (failureCount > 0) process.exit(1);
console.log(`Validated ${files.length} active handoff record(s).`);
