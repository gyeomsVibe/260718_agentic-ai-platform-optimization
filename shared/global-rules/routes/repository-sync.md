## Repository synchronization

- Consider synchronization only after a meaningful work unit completes or the user requests it. File saves, minor edits, timers, and unchanged worktrees are not triggers.
- Establish the baseline and stage only current-agent paths. Never use `git add .` or `git add -A`; preserve every non-owned change.
- Run repository checks. Inspect the staged diff for secrets, local settings, unexpected binaries, deletions, and generated output without its source. Hold on uncertainty.
- Fetch before pushing. If the remote is ahead or histories diverge, stop; never auto-pull, stash, rebase, merge, force-push, or rewrite history to continue.
- A global rule never grants standing push approval. A named repository may grant it in scoped rules; otherwise ask at the push boundary.
- For ordinary work, use Conventional Commits, at most one work commit, and one normal push per meaningful unit. Describe pull requests with changes, verification, and risks.
- Create a second handoff commit only for an explicit `handoff`, `인계`, or cross-platform resumption request. Handoff never expands other approvals.
