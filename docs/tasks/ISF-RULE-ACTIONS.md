# ISF-RULE-ACTIONS: Expression-Valued Rule Assignments

## Metadata

- Tree ID: `ISF-RULE-ACTIONS`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-14`
- Last updated: `2026-05-14`
- Owner: repo-local workflow

## Goal

Allow ISF rule actions to assign expression values where the expression can be
validated, lowered, scheduled, reported, and generated without weakening the
current rule guard, delayed trigger, and conflict semantics.

## Non-Goals

- Do not reintroduce the removed transaction `(assign ...)` keyword in this
  tree; compatibility decisions belong to `ISF-COMPATIBILITY`.
- Do not bypass `.fsm` expression validation by emitting raw scheduler text.
- Do not choose a conflict winner for expression-valued assignments without
  the policy from `ISF-CONFLICTS` and `ISF-RESOURCE-PRIORITY`.

## Acceptance Criteria

- Current rule action parsing and malformed-boundary behavior is inventoried.
- Expression-valued rule assignment syntax is documented precisely.
- Expressions lower through structured scheduler/`.fsm` expression paths,
  including width and symbol validation.
- Same-target expression assignments participate in the documented conflict
  policy.
- Schedule reports and public contract metadata describe the widened rule
  assignment family.
- Focused regressions cover valid expressions, malformed expressions,
  conflicts, CLI behavior, and docs.

## Task Tree

- ID: `ISF-RULE-ACTIONS`
  Status: `active`
  Goal: `Ship expression-valued rule assignments.`
  Children: `ISF-RULE-ACTIONS.1`, `ISF-RULE-ACTIONS.2`,
  `ISF-RULE-ACTIONS.3`, `ISF-RULE-ACTIONS.4`, `ISF-RULE-ACTIONS.5`

- ID: `ISF-RULE-ACTIONS.1`
  Status: `pending`
  Goal: `Inventory current rule action parser/lowering/report behavior.`
  Acceptance: `The task file lists accepted rule actions, malformed rule
  action diagnostics, scalar-only limits, storage/report metadata, and conflict
  touchpoints.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-RULE-ACTIONS.2`
  Status: `pending`
  Goal: `Specify expression-valued rule assignment syntax and semantics.`
  Acceptance: `The tree records accepted expression forms, symbol visibility,
  width rules, assignment family, guard interaction, and rejected cases.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-RULE-ACTIONS.3`
  Status: `pending`
  Goal: `Implement expression lowering for rule assignments.`
  Acceptance: `Valid expressions preserve through scheduled FSM emission
  and HDL generation, while invalid expressions fail before emission.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-RULE-ACTIONS.4`
  Status: `pending`
  Goal: `Integrate rule expressions with conflict tracking and reports.`
  Acceptance: `Expression-valued rule assignments are counted, reported, and
  checked against same-target conflict policy.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-RULE-ACTIONS.5`
  Status: `pending`
  Goal: `Add tests and synchronize docs/contracts.`
  Acceptance: `Focused tests and docs cover valid expression assignments,
  malformed cases, conflict cases, schedule report behavior, and public
  contract updates.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-RULE-ACTIONS.1` | `pending` | The existing scalar-only rule action boundary must be inventoried before widening it. |

## Decisions

- `2026-05-14`: Rule action widening is tracked independently from legacy
  transaction `assign` compatibility so the supported rule surface can move
  without reviving removed syntax accidentally.

## Open Questions

- Should rule assignment expressions initially share the same expression domain
  as transaction `(update var expr)`, or a narrower domain?
- How much width inference is required here versus delegated to
  `ISF-DATA-WIDTHS`?

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-14` | `ISF-RULE-ACTIONS` | `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-RULE-ACTIONS` | `R14: map ISF objectives to task trees` | Initial tree creation belongs to the ISF objective task-tree coverage slice. |

## Changelog

- `2026-05-14`: Created the active ISF rule-action task tree.
