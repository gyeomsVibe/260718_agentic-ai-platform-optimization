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

For every source family, record the source identifier, `preserve` or `adapt` or `omit`, normalized rule or omission reason, destination when retained, and evidence status. Reference private local assets by safe name or path only; never reproduce their confidential instruction bodies.

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

The forge ends at `STATIC_CANDIDATE` or, after deterministic checks, `STRUCTURE_VALIDATED`.

Promotion requires a separate workflow with retained evidence for explicit trigger and non-trigger behavior, representative task success, incomplete-input handling, safety refusal, no-Skill baseline comparison, and named-platform smoke tests.

Do not install globally, overwrite a canonical Skill, modify synchronization rules, publish, deploy, commit, or push unless the user separately authorizes that action.
