# Adaptive nonstop control loop

This maintained design closes the gap between executing a prepared card and adapting when the card, design, or environment has changed. It applies to Codex, Claude Code, and Antigravity through the shared core.

## State machine

`OBSERVE -> IMPACT -> REDESIGN -> CONTRACT -> EXECUTE -> CRITIQUE -> VERIFY -> RECORD -> OBSERVE`. A material change sends the process back to `IMPACT`; it does not wait for another user start command. Only one tool owns a writing step.

## Change-impact gate

A change to requirements, evidence, design, ownership, tool availability, acceptance results, or approval scope invalidates every dependent assumption and card. The conductor preserves the user goal and safety boundary, updates the design and fixed acceptance, publishes and lints a hash-fixed contract, then selects the smallest dependency-ready step. A stale `READY` label is not authority to execute.

Tool availability changes only when `coord route` confirms a route change; an `UNKNOWN` heartbeat does not. A card is re-planned at most twice, then the conductor changes route once. A 3x cost regression is a failed gate, not permission to loop. If an independent reviewer is unavailable, the verdict stays `UNKNOWN`, the author never self-approves, and another ready card may proceed.

## Terminal gate

A user-facing turn may stop only when one condition is evidenced: the objective is complete and no internal dependency remains; a necessary human-only action is reached and is not already approved for this scope; or every safe route is externally blocked after a durable handoff and zero-paid-token watcher are armed. Tool review, tests, builds, worker completion, PR preparation, link production, and the next card stay inside the agent loop.

The internal-dependency classifier never overrides the human-only safety list. A watcher records its expiry and is re-armed or hands off to the sentinel/schedule. A merge link is shown only after live state proves the PR is `OPEN` and mergeable; supersession or closure is reported in the same update.

## Red-team cases

- A card is `READY` but its acceptance no longer measures the changed design: invalidate and redesign it.
- Claude or Antigravity must review next: route the contract directly; do not list the review as user work.
- No PR exists yet: create and verify the local release packet when authorized; do not tell the user to restart the process.
- A true push, deploy, deletion, payment, credential, permission, or account boundary is reached: fail closed and request only that exact action.
- A model is limited: use the ordered deputy, deterministic path, or durable mailbox; unchanged waiting never wakes a paid model.
