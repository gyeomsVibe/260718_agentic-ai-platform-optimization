## Repository synchronization

- Treat a meaningful completed work unit or an explicit user sync request as the only synchronization trigger. File saves, minor edits, timers, and an unchanged worktree are not triggers.
- Before staging, identify the baseline and separate paths created by the current agent from user, other-session, tool-generated, or unknown changes. Preserve every non-owned path.
- Stage only explicit owned paths. Never use `git add .` or `git add -A` for synchronization.
- Run the repository's relevant checks and inspect the staged diff for secrets, machine-local configuration, unexpected binaries, or destructive changes. If any check or ownership decision is uncertain, hold and report.
- Fetch before a push. If the remote is ahead or the history diverged, stop and report; never auto-pull, rebase, merge, force-push, or rewrite history to continue.
- A global rule does not grant standing push approval. A named repository may grant it only in its own scoped rules; otherwise ask at the push boundary.
- For ordinary work, use at most one work commit and one normal push per meaningful work unit. Do not create a handoff record merely because work ended or an agent changed.
- Use a work-commit plus handoff-commit protocol only when the user explicitly requests `handoff`, `인계`, or cross-platform resumption. A handoff never expands approvals for deployment, releases, account changes, or other repositories.
