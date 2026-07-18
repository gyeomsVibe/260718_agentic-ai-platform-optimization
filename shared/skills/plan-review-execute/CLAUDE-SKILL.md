---
name: plan-review-execute
description: Activate only when the user explicitly says "MIA모드 발동" to start the 기획·검토·실행 모드 for an evidence-backed product, business, or meaningful technical decision. Do not activate for similar natural-language requests.
argument-hint: "MIA모드 발동: [기획|검토|실행|검증] <목표>"
user-invocable: false
---
# 기획·검토·실행 모드

Activate this workflow only when the user says the exact trigger phrase MIA모드 발동.
The phrase starts the 기획·검토·실행 모드; it is not authority for publishing,
payments, account changes, external writes, or any other irreversible action.
Do not activate from similar everyday wording such as 기획, 검토, 사업성, 아이디어,
기능, or 계획 alone.

## Select a stage

Default to `기획` when the user does not state a stage.

| Stage | Purpose | Write permission |
|---|---|---|
| `기획` | Define the problem, outcome, stakeholders, hypotheses, and evidence needed | None |
| `검토` | Compare alternatives; test value, feasibility, viability, and risks; make a Go/Pivot/No-Go decision | None |
| `실행` | Deliver the approved smallest experiment or scoped local change | Only requested, reversible local changes |
| `검증` | Compare results with the success threshold and decide to iterate, scale, or stop | None unless a requested report is created |

Ask one high-value question only when a missing decision would materially alter
scope, risk, or the recommendation.

## Professional workflow

### 1. 기획 — frame the opportunity

Create an Opportunity Brief:

- Decision to make, decision owner, deadline, and constraints.
- Target user or stakeholder, their job-to-be-done, and the observable problem.
- Desired outcome, measurable success signal, non-goals, and key hypothesis.
- Evidence map: verified facts, assumptions, unknowns, and the cheapest credible
  way to reduce each important uncertainty.

Research time-sensitive claims using primary or official sources and cite them.
Do not force commercial analysis on personal, maintenance, or purely technical work.

### 2. 검토 — make the decision auditable

Compare 2–3 practical options, including doing nothing when relevant. Review each
option through these lenses:

- **Value (desirability):** does it solve a meaningful user or stakeholder need?
- **Feasibility:** can the team, technology, time, and dependencies support it?
- **Viability:** are cost, policy, security, legal, and operational effects acceptable?
- **Risk:** identify the highest-impact uncertainty, mitigation, and rollback path.

End with a decision gate: `Go`, `Pivot`, `No-Go`, or `Research more`. State the
reason, decision owner, evidence threshold, and what would change the decision.

### 3. 실행 — deliver the smallest useful proof

After a `Go` decision and the user's requested scope, define:

- Smallest viable experiment or delivery; exclusions and acceptance criteria.
- Owner, milestones, dependencies, and a reversible rollback approach.
- Leading metric, measurement method, decision date, and success threshold.

For code or configuration work, translate this into a scoped implementation plan,
make only approved local reversible changes, then run proportionate verification.

### 4. 검증 — close the learning loop

Record actual evidence against the threshold. Recommend `iterate`, `scale`, or
`stop`, and separate demonstrated learning from remaining assumptions. Update the
next decision rather than treating activity as success.

## Execution gates

- Skill invocation never authorizes deletion, deployment, publishing, payments,
  account or permission changes, production-data writes, or third-party contact.
  Obtain separate explicit approval for each.
- Prefer a dry run, mock, sandbox, or reversible local change when available.
- Do not install packages, plugins, or MCP servers unless the user approves after
  their purpose and impact are clear.
- For legal, medical, tax, investment, or other high-stakes matters, use current
  primary sources, state uncertainty, and do not present general information as
  professional advice.

## Output by stage

Return only the useful sections:

| Stage | Deliverable |
|---|---|
| `기획` | Opportunity Brief and evidence plan |
| `검토` | Decision Memo: options, trade-offs, risks, and decision gate |
| `실행` | Delivery Card: scope, acceptance criteria, plan, and verification |
| `검증` | Learning Report: result, evidence, decision, and next experiment |
## Quality Circuit — fast, evidence-backed decisions

Apply this circuit before and during the selected stage, but only to the degree
justified by the decision. It must not turn a small reversible task into ceremony.

1. **Intent Lock:** retain the requested task, target, depth, format, inclusions,
   exclusions, user-effort limit, and success condition. Check the final result
   against this lock before responding.
2. **Evidence Gate:** separate observed facts, user evidence, assumptions, and
   unknowns. Use no external research for stable local work (`R0`); use the
   smallest sufficient primary-source check for volatile or material claims
   (`R1–R3`). Stop when the material evidence gap is closed.
3. **Candidate Portfolio:** only for irreversible, high-cost, safety-sensitive, or
   architecture-level decisions, create 2–4 materially different options; apply
   hard constraints, then select, merge, reject, or defer. Do not force this for
   a small reversible task.
4. **Judgment Contract:** state the relevant selection dimensions—user value,
   problem fit, coherence, simplicity, reversibility, maintenance cost, and
   evidence strength—plus must-keep, must-reject, minority objection, and revisit
   condition.
5. **Medium Selection:** use the cheapest valid medium: Decision Brief/PRD for
   scope, system design for responsibilities, prototype for interaction, local
   change for behavior, and validation evidence for readiness. State what the
   chosen medium cannot prove.
6. **Maturity and Freeze Guard:** label meaningful artifacts `DIRECTION_DRAFT`,
   `EXPLORATION_ARTIFACT`, `STATIC_CANDIDATE`, or `VERIFIED_RESULT`. A polished
   first artifact is not proof; pause before commitment when alternatives,
   acceptance criteria, or evidence remain incomplete.
7. **Regression and Revisit:** before final delivery, check query fidelity,
   evidence coverage, constraint preservation, and avoidable complexity. Record
   a later retest only when the cause is model capability, platform, cost, or
   timing—not when the concept is invalid or unsafe.

For a material decision, apply the Net Complexity check before expanding work:
prefer reuse, merge, scope reduction, or deletion over a new module, tool,
document, or agent unless the new artifact reduces material risk or creates a
measured learning gain. A `VERIFIED_RESULT` requires observed evidence appropriate
to the claimed behavior; a static check or attractive prototype does not qualify.