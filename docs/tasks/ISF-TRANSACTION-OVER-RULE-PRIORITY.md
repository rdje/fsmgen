# ISF-TRANSACTION-OVER-RULE-PRIORITY: Transaction Over Rule Priority

## Metadata

- Tree ID: `ISF-TRANSACTION-OVER-RULE-PRIORITY`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-23`
- Last updated: `2026-05-23`
- Owner: repo-local workflow

## Goal

Ship the covered same-target transaction-over-rule priority case without
creating implicit fake ports or changing unordered conflict policy.

The implementation needs a reviewable scheduled `.fsm` state-active guard
surface first. That guard must let a non-state rule DT say "fire only when
this transaction state is not active" without treating the generated
state-enable name or `current_state` enum symbols as user module inputs.

## Non-Goals

- Do not implement transaction/transaction priority beyond ordinary state
  mutual exclusion.
- Do not implement drive/rule arbitration, resource arbitration, or
  transaction lifetime ownership.
- Do not use generated `STATE_en` names as authored guard signals because
  that creates implicit input ports and collides with backend-generated state
  enable wires.
- Do not change rule-over-transaction priority, rule/rule priority,
  unordered rule/transaction conflict diagnostics, priority-cycle diagnostics,
  or mixed-timing diagnostics.
- Do not expose arbitrary state-register expressions as a general user-facing
  ISF feature.

## Acceptance Criteria

- Scheduled `.fsm` can represent a bounded state-active guard for non-state DT
  enable conditions without creating fake `current_state`, state-name, or
  state-enable input ports.
- The guard parses through the normal `.fsm` frontend and reaches
  SystemVerilog generation with internal state-register comparisons.
- ISF transaction-over-rule priority lowers the covered same-target data case
  by keeping the transaction assignment unchanged and guarding the lower-rule
  assignment off while the winning transaction state is active.
- Provenance and schedule reports identify the transaction winner and rule
  loser through the existing `priority_resolutions[]` shape.
- Existing rule-over-transaction, rule/rule, unordered conflict, cycle, and
  mixed-timing behavior remains unchanged.
- ISF spec, downstream integration handoff, public contract, mdBook, roadmap
  status, task-tree index, and live docs are synchronized.
- Focused validation covers the new state-active scheduled `.fsm` guard,
  transaction-over-rule priority, existing priority regressions, report
  projection, public metadata, and book/spec audits; broader ISF regression
  runs if focused checks pass.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-TRANSACTION-OVER-RULE-PRIORITY`
  Status: `active`
  Goal: `Ship covered transaction-over-rule same-target data priority`
  Children: `ISF-TRANSACTION-OVER-RULE-PRIORITY.1`,
  `ISF-TRANSACTION-OVER-RULE-PRIORITY.2`

- ID: `ISF-TRANSACTION-OVER-RULE-PRIORITY.1`
  Status: `done`
  Goal: `Select the bounded transaction-over-rule priority slice`
  Acceptance: `The active tree, frontier, non-goals, acceptance criteria, and
  live roadmap/docs identify the exact selected implementation boundary before
  any code changes.`
  Verification: `documentation-only selection review`
  Commit: `this commit`

- ID: `ISF-TRANSACTION-OVER-RULE-PRIORITY.2`
  Status: `active`
  Goal: `Implement scheduled state-active guards and transaction-over-rule lowering`
  Acceptance: `The scheduled .fsm guard, priority lowering, focused tests,
  public contract metadata, specs, mdBook, and live docs are updated and
  validated.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-TRANSACTION-OVER-RULE-PRIORITY.2` | `active` | `The selected implementation boundary is recorded; behavior-bearing work can start after this selection commit.` |

## Decisions

- `2026-05-23`: Select transaction-over-rule priority only for the covered
  same-target data case already handled in the opposite direction. The lowerer
  can suppress the lower-priority rule assignment only after scheduled `.fsm`
  has a state-active guard surface that does not become an implicit port.
- `2026-05-23`: Reject using generated `STATE_en` names in scheduled `.fsm`
  text. A probe showed that such names become implicit module inputs and then
  collide with backend-generated state-enable assignments.

## Open Questions

- None for the selected leaf. Broader priority/resource arbitration remains
  backlog and is not required for this tree.

## Blockers

- None for selection. Implementation depends on landing the bounded
  state-active scheduled `.fsm` guard before changing ISF priority lowering.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-23` | `ISF-TRANSACTION-OVER-RULE-PRIORITY.1` | `documentation-only selection review` | `passed` |
| `2026-05-23` | `ISF-TRANSACTION-OVER-RULE-PRIORITY.2` | `pending` | `pending` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-TRANSACTION-OVER-RULE-PRIORITY.1` | `this commit: ISF-TRANSACTION-OVER-RULE-PRIORITY.1: select transaction-over-rule priority` | `selection slice` |
| `ISF-TRANSACTION-OVER-RULE-PRIORITY.2` | `pending` | `pending` |

## Changelog

- `2026-05-23`: Created and activated task tree; selected
  `ISF-TRANSACTION-OVER-RULE-PRIORITY.2` as the implementation frontier after
  the selection commit.
