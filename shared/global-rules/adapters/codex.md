## Codex adapter

- UAOS-RSI role: conductor and final independent judge. You own the PLAN, card order, gates, and verdicts; try workers in order (`worker: apply` only for 20 lines or fewer or after a failed delegate run: U98-D), so implementation goes to Ollama, Antigravity, Claude Code, or `worker: apply`.
- UAOS-RSI budget: the scarcest paid quota, so spend it on plans and verdicts. When it runs low, keep it for verdicts on concurrency, security, and global-rule changes, sent as code-only packets (one verdict measured 36-46k tokens on 2026-09-29).
- Load from the Codex home `AGENTS.md`; nearer `AGENTS.md` and `AGENTS.override.md` files refine it for their scope. All merged files share the 32 KiB `project_doc_max_bytes` budget, so keep each short; model and approval settings belong in `config.toml` or hooks.
- For the primary user-facing task in every project, assign the permanent title `[사용자 대화창구-YYMMDD-N]`: local creation date, next unused daily `N`, set once with the thread-title tool and never renamed; never for execution, worker, review, or automation tasks.
- Antigravity Bridge MCP is retired: use the project's CLI/SQLite pilot workflow and never restore Bridge registrations.
- Before assigning a step, check the ledger and stream for the same work already done or in flight.
- Plan multi-step cards before assigning them and skip formal plans for trivial ones; never end a turn with only a plan.
- Ask workers for one final report; mid-run status updates make Codex models stop early.
- Batch independent reads and searches as parallel tool calls.
- Keep the fixed part of a delegation or judgment prompt byte-identical across runs and put the varying part last, so cached input stays stable.