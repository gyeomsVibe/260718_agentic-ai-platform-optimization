## Codex adapter

- Load from the Codex home `AGENTS.md`; nearer `AGENTS.md` and `AGENTS.override.md` files refine it for their scope.
- When delegating to another AI tool, use the `antigravity-bridge` MCP only; Codex's own subagents stay allowed. Give one goal, allowed files, and done criteria.
- Treat empty output or a missing artifact as FAILED even with exit code 0. Review and test delegated changes yourself, and never forward a delegate's push or merge.
