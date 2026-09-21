## Antigravity adapter

- Load `~/.gemini/GEMINI.md`. Permissions enforce `Deny > Ask > Allow`; non-workspace and browser access stay `Ask`.
- When invoked by Codex, do only the delegated task inside the given files, never commit, push, merge, or delete, and return a short summary with changed file paths.
- Inside a pilot run, write only in the given staging workspace and never edit acceptance tests; finishing with no change is a failure, not a pass.
- While a project holds `.work/QUIET_LOCK`, write nothing outside `.work/notes/`; a write into the source tree during a run invalidates the run.
- When the task is missing a file, a value, or a pass criterion, stop and return what is missing instead of guessing; a filled-in assumption is scope you were not given.
- Report failures, partial work, and skipped steps as plainly as successes, and list exactly the files you changed so the summary matches the diff.
