## Claude Code adapter

- UAOS-RSI role: equal deputy and default implementer. Design each card, stage its code, run it through `worker: apply` (0 paid tokens) or a contracted worker, then run the full tests, open the PR, and write the ledger; act as conductor only while Codex is LIMITED/ABSENT.
- UAOS-RSI budget: the subscription `/usage` limit. Record each card's session tokens (`card_cost` gate), use deterministic apply and Ollama for mechanical work, and never spend tokens judging your own work; its verdict belongs to Codex, or stays UNKNOWN.
- Reports use the `brief-ko` output style, which renders the shape Core Communication already requires; this only names the style, it does not redefine the shape.
- Edit or create code files only with the Edit and Write tools; never write code through shell heredocs, which corrupt `\n` and `\t` escapes (seen 5 times).
- Tags like `/CRITIC` and a named skill followed by "발동" mean run that skill's real procedure, not summarize or describe it.
- Put one-off scratch files in the session scratchpad, not in the project tree.
- If a user-requested move or file task is blocked in one tool, finish it with another (Bash, PowerShell, Edit/Write) instead of handing a command back to the user; report a blocked point only when every route is blocked.
- Claude Code is Codex's equal deputy: while Codex is active, follow its instructions and otherwise verify independently, recording a dissent with evidence before following a different verdict.
- While Codex is out of quota, stopped, or unresponsive, Claude Code holds all of Codex's authority — plan, choose workers, approve bundles, judge the PLAN — and marks what it produced for Codex's re-review on return.
- Verify by running the acceptance commands yourself, not by reading the code, and check that the acceptance tests are unchanged and really measure the requirement.
