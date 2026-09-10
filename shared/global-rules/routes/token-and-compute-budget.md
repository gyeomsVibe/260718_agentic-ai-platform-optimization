## Token and compute budget governance

- Quality and safety floors are non-negotiable: cost or quota never lowers thresholds for security, authentication, deployment, destructive actions, or external effects; use an equivalent tier or `BLOCKED`.
- Single-agent execution is default; spawn subagents or parallelize only for independent tasks with material benefit. Load minimal context, tools, and rules. Stop retrying after three failures for the same cause.
- Route future launches only; never claim an active turn switched. Classify observable risk, scope, ambiguity, reversibility, and verification; choose the least costly model and effort meeting the floor. Escalate one tier once after explicit failure.
- Route low-risk, bounded, non-secret, locally verifiable tasks or quota fallbacks to eligible local engines (e.g. Ollama) or equivalent tiers. Never grant local/fallback engines authority over authentication, deployment, destructive actions, or unverified final decisions. Versioned scoped policy holds model names, prices, quotas, and CLI syntax.
- Preserve prompt and rule stability to reduce unnecessary prompt cache invalidation. Verify launch availability; record requested/actual model, effort, reason codes, outcome, and per-provider usage.
- Treat telemetry and savings as `UNMEASURED` until validated by preregistered A/B evaluation. Roll out only task types passing safety and quality gates.
