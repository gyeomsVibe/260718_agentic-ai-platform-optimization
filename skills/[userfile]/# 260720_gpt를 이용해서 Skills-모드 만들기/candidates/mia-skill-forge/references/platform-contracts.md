# Cross-platform Skill Contracts

Use a common-first design. Platform behavior changes over time, so verify the current official contract before installation or runtime certification.

## Common contract

- Store instructions in a directory whose entry file is `SKILL.md`.
- Use lowercase letters, digits, and hyphens for `name`; match the directory name.
- Make `description` explain what the Skill does and when it should run.
- Keep common frontmatter to `name` and `description` unless a target requires a derived extension.
- Put the normal path in `SKILL.md` and link directly to one-level references for detailed material.
- Keep scripts deterministic and dependency-light.
- Do not place audit reports, benchmarks, changelogs, installation guides, or unrelated documentation in the runnable Skill folder.

## Codex adapter

- Project-scoped discovery uses `.agents/skills/<name>/SKILL.md`; user-scoped discovery uses the supported Codex skills directory.
- Use `$<skill-name>` for reliable explicit invocation.
- Put optional UI metadata in `agents/openai.yaml`.
- Ensure `interface.default_prompt` mentions `$<skill-name>`.
- Set `policy.allow_implicit_invocation: false` while trigger precision is unproven.
- Do not treat display metadata as behavioral verification.

## Claude Code adapter

- Project-scoped Skills normally live in `.claude/skills/<name>/SKILL.md`.
- Invocation commonly uses `/skill-name`; verify the active product contract before deployment.
- Keep Claude-specific frontmatter or controls in a derived variant only when required; do not contaminate the common canonical body.

## Antigravity adapter

- Workspace Skills use `.agents/skills/<name>/SKILL.md`.
- Verify the current global configuration path on the target machine before writing.
- Depend on the common `description` for discovery and retain the same core behavior.
- Do not infer notebook, desktop, or another platform installation from this repository candidate.

## Drift controls

1. Author the common Skill first.
2. Generate the smallest platform adapter.
3. Compare normalized common bodies before promotion.
4. Record every intentional divergence and its platform reason.
5. Rerun one positive trigger, one negative trigger, one core task, and one safety refusal on every named platform.

A matching file tree is not proof of matching runtime behavior.
