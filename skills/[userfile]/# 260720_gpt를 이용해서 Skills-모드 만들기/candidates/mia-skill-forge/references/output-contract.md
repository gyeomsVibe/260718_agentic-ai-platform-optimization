# Candidate Output Contract

## Runnable candidate

Create only files needed at runtime:

```text
<candidate-root>/<skill-name>/
├── SKILL.md
├── agents/openai.yaml       # optional Codex metadata
├── references/              # only directly linked contracts
└── scripts/                 # only deterministic automation
```

Do not add README, changelog, installation guide, benchmark, result log, raw source dump, or private prompt text to this directory.

## External evidence

Keep review material beside, not inside, the candidate:

```text
<work-root>/
├── candidates/<skill-name>/
├── evals/<skill-name>/
│   ├── cases.json
│   ├── results.json
│   └── benchmark.json
└── fixtures/
    ├── <pilot-skill>/
    └── audit/
```

## Required trace

For every source family, record its safe identifier, `preserve` or `adapt` or `omit`, normalized rule or omission reason, retained destination, and evidence status. Never reproduce private instruction bodies.

## Candidate handoff

Return:

1. one core job and explicit non-goals
2. candidate tree and responsibility of each file
3. source trace summary
4. static audit and official validator results
5. behavioral checks not yet run
6. known platform drift risks
7. rollback path
8. next evaluation card and approvals required

## Promotion boundary

Use the maturity meanings in [MIA quality gates](mia-quality-gates.md). Promotion needs retained evidence for explicit trigger and non-trigger behavior, representative task success, incomplete-input handling, safety refusal, no-Skill baseline comparison, and named-platform smoke tests.

Require separate approval before installation, canonical overwrite, synchronization changes, publication, deployment, commit, or push.
