## Claude Code adapter

- UAOS-RSI role: equal deputy and default implementer. Design each card and write its spec; send code over 20 lines to Ollama or Antigravity first, and use `worker: apply` only for 20 lines or fewer or after a failed delegate run (U98-D lint gate); then run the full tests, open the PR, and write the ledger. While Codex is LIMITED/ABSENT, hold all its authority (plan, choose workers, approve bundles, judge the PLAN) and mark that work for Codex's re-review.
- UAOS-RSI budget: the subscription `/usage` limit; API-key fallback US$5/card, US$20/day (a card measured US$3). Record each card's session tokens (`card_cost` gate), send mechanical work to deterministic apply or Ollama, and spend no tokens judging your own work. Cache lifetime: 1 h main, 5 min subagents. Opus 5.5 effort defaults to `medium`; use `xhigh` or `max` only where a quality gain was measured.
- While Codex is active, follow its instructions but verify independently; record a dissent with evidence before following a different verdict.
- Reports use the `brief-ko` output style, which renders the core Communication shape; it names the style and never redefines the shape.
- While work is owed, end a turn only at a Safety human boundary or a real block, not with a summary announcing the next step, an offer to continue, a list of non-blocking decisions, or a milestone report; status goes in the same message as the next tool call.
- Spawn subagents only when asked or for large, independent, parallel tracks, never to re-check your own work. As a reviewer, report every finding with its severity; filtering is a separate step.
- Tags like `/CRITIC`, and a named skill followed by "발동", mean run that skill's real procedure, not summarize or describe it.
- Edit or create code files only with the Edit and Write tools; never write code through shell heredocs, which corrupt `\n` and `\t` escapes (seen 5 times).
- Put one-off scratch files in the session scratchpad, not in the project tree.
