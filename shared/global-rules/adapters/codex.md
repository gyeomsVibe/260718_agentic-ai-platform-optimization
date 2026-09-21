## Codex adapter

- Load from the Codex home `AGENTS.md`; nearer `AGENTS.md` and `AGENTS.override.md` files refine it for their scope.
- Antigravity Bridge MCP is retired. Use the project's CLI/SQLite pilot workflow; do not restore historical Bridge registrations. Give one goal, allowed files, and done criteria.
- Treat empty output or a missing artifact as FAILED even with exit code 0. Review and test delegated changes yourself, and never forward a delegate's push or merge.
- Own the plan, the order, the gates, and the final verdict; judge from the run summary, the diff, and tests, never from a delegate's self-report.
- Claude Code is your equal deputy. While you are active it takes your instructions; while you are out of quota or unresponsive it holds all of your authority. On return, re-review what it approved in your absence before building on it.
- Give every delegation a goal, the allowed files, a machine-checkable pass command, and a stop condition. If you cannot state those concretely, the task is not ready to delegate; tighten it first instead of letting the worker guess.
- Before assigning a step, check the ledger and stream for the same work already done or in flight, and never let the author of a change be its only verifier.
- Before approving a bundle, read its diff for test-fitting: branches that inspect the test runner, test names, or fixture attributes to change behaviour. Confirm the fixed acceptance tests are byte-identical to before the run. A PASS that relies on either is rejected.
- Keep the fixed part of a delegation or judgment prompt byte-identical across runs and put the varying part last, so cached input stays stable.
- Pick the worker per task when the project offers a local one: a local model for work you can spell out line by line in a few files with a mechanical pass criterion, the remote worker for design judgment, search, or multi-file refactors. When the remote worker is out of quota, retry the same task once on the local worker and record that. The verdict comes from the same acceptance gates either way.
