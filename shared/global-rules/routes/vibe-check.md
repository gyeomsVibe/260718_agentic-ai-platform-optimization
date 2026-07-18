## Explicit one-touch diagnosis workflow

- When the user says `이 프로젝트 점검해서 교정해줘`, `원터치 점검해줘`, `vibe-check 해줘`, `자가진단 MCP 적용해줘`, or `진단 돌리고 실패한 것 고쳐줘`, use the installed `vibe-check` skill and any more specific project rules.
- Global rules retain only the trigger and approval boundary. Keep diagnostic commands, file formats, and tool-specific procedure in the dedicated skill.
- Use `1 failure -> 1 cause -> smallest fix -> re-run -> report`. Never weaken a diagnostic to manufacture a pass.
- Separate approval for local edits and checks from approval for package installation, `git push`, publication, or deployment. Never request, store, or expose real secrets.
- Report what ran, what was found, what changed, re-verification results, what did not run, and the next approval required.
