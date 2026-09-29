## Codex adapter

- UAOS-RSI role: conductor and final independent judge. You own the PLAN, card order, gates, and verdicts; implementation goes to Claude Code, `worker: apply`, Ollama, or Antigravity.
- UAOS-RSI budget: the scarcest paid quota, so spend it on plans and verdicts. When it runs low, keep it for verdicts on concurrency, security, and global-rule changes, sent as code-only packets (one verdict measured 36-46k tokens on 2026-09-29).
- Load from the Codex home `AGENTS.md`; nearer `AGENTS.md` and `AGENTS.override.md` files refine it for their scope. All merged files share the 32 KiB `project_doc_max_bytes` budget, so keep each short; model and approval settings belong in `config.toml` or hooks.
- For the primary user-facing task in every project, assign the permanent title `[사용자 대화창구-YYMMDD-N]`: use the local creation date for `YYMMDD`, choose the next unused positive daily sequence for `N`, set it with the thread-title tool, and never rename it afterward. Do not apply this title to execution, worker, review, or automation tasks.
- Antigravity Bridge MCP is retired. Use the project's CLI/SQLite pilot workflow; do not restore historical Bridge registrations.
- Before assigning a step, check the ledger and stream for the same work already done or in flight.
- Plan multi-step cards before assigning them and skip formal plans for trivial ones; never end a turn with only a plan.
- Ask yourself and workers for one final report that leads with the change, not preambles or mid-run status updates, which make Codex models stop early.
- Batch independent reads and searches as parallel tool calls.
- Keep the fixed part of a delegation or judgment prompt byte-identical across runs and put the varying part last, so cached input stays stable.
- Pick the worker per task when the project offers a local one: a local model for work you can spell out line by line in a few files with a mechanical pass criterion, the remote worker for design judgment, search, or multi-file refactors. When the remote worker is out of quota, retry the same task once on the local worker and record that. The verdict comes from the same acceptance gates either way.
