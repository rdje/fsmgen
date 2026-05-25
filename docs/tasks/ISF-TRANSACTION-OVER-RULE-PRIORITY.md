# ISF-TRANSACTION-OVER-RULE-PRIORITY: Transaction Over Rule Priority

## Metadata

- Tree ID: `ISF-TRANSACTION-OVER-RULE-PRIORITY`
- Status: `done`
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
  Status: `done`
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
  Commit: `71574f34`

- ID: `ISF-TRANSACTION-OVER-RULE-PRIORITY.2`
  Status: `done`
  Goal: `Implement scheduled state-active guards and transaction-over-rule lowering`
  Acceptance: `The scheduled .fsm guard, priority lowering, focused tests,
  public contract metadata, specs, mdBook, and live docs are updated and
  validated.`
  Verification: `syntax, focused priority/state-active/public/spec/book checks,
  mdBook build, broad ISF regression, post-closure audits, git diff check`
  Commit: `7a3222a1 ISF-TRANSACTION-OVER-RULE-PRIORITY.2: ship transaction-over-rule priority`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `The selected transaction-over-rule priority slice is implemented, documented, validated, and ready for commit.` |

## Decisions

- `2026-05-23`: Select transaction-over-rule priority only for the covered
  same-target data case already handled in the opposite direction. The lowerer
  can suppress the lower-priority rule assignment only after scheduled `.fsm`
  has a state-active guard surface that does not become an implicit port.
- `2026-05-23`: Reject using generated `STATE_en` names in scheduled `.fsm`
  text. A probe showed that such names become implicit module inputs and then
  collide with backend-generated state-enable assignments.
- `2026-05-23`: Ship `(state_active STATE)` as a bounded scheduled `.fsm`
  expression surface for generated guards. The parser validates the referenced
  state against declared regular FSM states, lowers the expression to the
  internal `current_state == STATE` comparison, and keeps `current_state`,
  state enum literals, and generated state-enable names out of the authored
  module input set.
- `2026-05-23`: Lower covered transaction-over-rule same-target data priority
  by leaving the winning transaction assignment in its state DT and guarding
  the lower-priority non-state rule assignment with the inverse transaction
  state-active condition. Transaction/transaction priority, unordered
  conflicts, mixed-timing conflicts, and broader resource arbitration remain
  deferred or unchanged.

## Open Questions

- None for the selected leaf. Broader priority/resource arbitration remains
  backlog and is not required for this tree.

## Blockers

- None. The selected implementation leaf is complete.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-23` | `ISF-TRANSACTION-OVER-RULE-PRIORITY.1` | `documentation-only selection review` | `passed` |
| `2026-05-23` | `ISF-TRANSACTION-OVER-RULE-PRIORITY.2` | `perl -Iperl -c perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm`; `perl -Iperl -c perl/FSM/Adapter/FSMGenFull/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm` | `passed` |
| `2026-05-23` | `ISF-TRANSACTION-OVER-RULE-PRIORITY.2` | `prove -Iperl t/1345-fsm-state-active-guard.t t/1219-isf-rule-transaction-priority.t` | `passed: Files=2, Tests=8` |
| `2026-05-23` | `ISF-TRANSACTION-OVER-RULE-PRIORITY.2` | `prove -Iperl t/1345-fsm-state-active-guard.t t/1219-isf-rule-transaction-priority.t t/1210-isf-priority-conflict-resolution.t t/1220-isf-arbitration-schedule-report.t t/1218-isf-rule-slot-resource-arbitration.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t` | `passed: Files=10, Tests=342` |
| `2026-05-23` | `ISF-TRANSACTION-OVER-RULE-PRIORITY.2` | `mdbook build docs/book` | `passed` |
| `2026-05-23` | `ISF-TRANSACTION-OVER-RULE-PRIORITY.2` | `./bin/ci-regression isf --no-book` | `passed: Files=250, Tests=1656` |
| `2026-05-23` | `ISF-TRANSACTION-OVER-RULE-PRIORITY.2` | `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t` | `passed: Files=6, Tests=347` |
| `2026-05-23` | `ISF-TRANSACTION-OVER-RULE-PRIORITY.2` | `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-TRANSACTION-OVER-RULE-PRIORITY.1` | `71574f34 ISF-TRANSACTION-OVER-RULE-PRIORITY.1: select transaction-over-rule priority` | `selection slice` |
| `ISF-TRANSACTION-OVER-RULE-PRIORITY.2` | `7a3222a1 ISF-TRANSACTION-OVER-RULE-PRIORITY.2: ship transaction-over-rule priority` | `implementation slice` |

## Changelog

- `2026-05-23`: Created and activated task tree; selected
  `ISF-TRANSACTION-OVER-RULE-PRIORITY.2` as the implementation frontier after
  the selection commit.
- `2026-05-23`: Shipped scheduled `.fsm` state-active guards and covered
  transaction-over-rule same-target data priority. Synchronized the ISF spec,
  downstream integration handoff, public contract, mdBook, roadmap status,
  task index, memory, development notes, live achievement status, and focused
  validation evidence.
