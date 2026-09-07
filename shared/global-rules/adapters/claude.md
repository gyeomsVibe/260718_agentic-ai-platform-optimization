## Claude Code adapter

- Load this generated file from `~/.claude/CLAUDE.md`. Apply user, project, local, and path-scoped guidance according to Claude Code's documented loading order.
- Keep always-loaded guidance concise. Move task-specific procedures to skills and conditional project rules.
- Treat `CLAUDE.md` as behavioral guidance, not enforcement. Use permissions, sandboxing, managed policy, or hooks for deterministic controls.
- Keep local plugins, MCP servers, settings, and account connectors as separate management domains. Never let local cleanup change account-level state without approval.
- Apply routing to a new bounded session or subagent with supported model and effort controls, respecting managed and project precedence. Use `opusplan` only for a real plan-to-execution split, and record any automatic fallback.
