# Skill Optimization Procedure

Use this procedure to improve an existing Skill without confusing activity with progress. Optimize observable behavior and maintenance cost, not document volume.

## 0. Lock intent and authority

Record the requested outcome, target users, target platforms, permitted writes, non-goals, and success threshold.

Output: an execution card with scope, exclusions, evidence needed, and rollback path.

## 1. Freeze a reproducible baseline

Capture before editing:

- canonical path, version or commit, and SHA-256
- current trigger and non-trigger examples
- representative task and safety cases
- structure, line count, resource count, and platform adapters
- known failures and unverified assumptions

Gate: stop if the baseline cannot be reproduced or the supposed defect has no evidence.

## 2. Diagnose one bottleneck

Classify the primary problem:

- `trigger`: missed or accidental activation
- `task`: poor or inconsistent task result
- `safety`: unsafe authority or side-effect handling
- `context`: excessive instructions or unnecessary loading
- `structure`: broken links, duplicate rules, or unclear responsibilities
- `drift`: common and platform-specific copies no longer mean the same thing
- `evidence`: completion or maturity is overstated

State one failure, one supported cause, and the smallest measurable correction. Do not bundle unrelated cleanup.

## 3. Compare the smallest candidate portfolio

Consider only materially different options:

1. `no-change`: retain the baseline and gather better evidence
2. `simplify`: remove or merge content while preserving behavior
3. `repair`: fix a demonstrated defect locally
4. `split`: separate a responsibility only when it reduces risk or context materially

Reject options that violate safety, authority, platform contracts, or user constraints. Prefer the lowest net complexity among options expected to meet the threshold.

## 4. Apply one reversible change

Edit a separate candidate or fixture before touching the canonical Skill. Preserve the source trace and record intentional semantic differences. Keep runtime files separate from evaluation evidence.

Gate: every new file must have one distinct reusable responsibility. Otherwise merge it or omit it.

## 5. Verify in layers

Run the cheapest valid layer first:

1. syntax, frontmatter, naming, links, sensitive filenames, and risky command patterns
2. explicit trigger and non-trigger cases
3. representative task, incomplete input, and safety refusal cases
4. no-Skill baseline comparison
5. named-platform smoke tests

Use the recovery loop in [MIA quality gates](mia-quality-gates.md) after a failure.

## 6. Measure net improvement

Compare baseline and candidate on:

| Dimension | Evidence |
|---|---|
| Trigger precision | False activations and missed explicit invocations |
| Task success | Predefined representative cases |
| Safety | Correct approval boundaries and refusal behavior |
| Context cost | Body size and resources loaded for the normal path |
| Maintenance | Duplicate rules, file count, and platform drift |
| Evidence strength | Reproducible checks versus assumptions |

A smaller file is not automatically better. A larger package must demonstrate a risk reduction or measured learning gain that justifies its cost.

## 7. Decide and hand off

Choose one outcome:

- `iterate`: a supported defect remains and a smaller next correction exists
- `scale`: thresholds passed on every claimed platform with retained evidence
- `stop`: the concept is invalid, unsafe, or not worth its complexity
- `no-change`: the baseline is adequate and modification lacks evidence

Use the maturity meanings and forbidden status transitions in [MIA quality gates](mia-quality-gates.md).

Report changed files, checks run and not run, remaining risks, rollback, and the next approval boundary.
