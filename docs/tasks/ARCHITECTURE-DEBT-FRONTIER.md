# ARCHITECTURE-DEBT-FRONTIER: Architecture Debt Frontier

## Metadata

- Tree ID: `ARCHITECTURE-DEBT-FRONTIER`
- Status: `active`
- Roadmap lane: `architecture`
- Created: `2026-06-05`
- Last updated: `2026-06-07`
- Owner: repo-local workflow

## Goal

Own the architecture debt items named in the 2026-06-05 remaining-work
inventory so convergence/refactor work is selected through task-tree leaves
rather than informal cleanup.

## Non-Goals

- Do not perform broad refactors without selecting an exact active leaf first.
- Do not change public behavior under an architecture-debt label without the
  same behavior, docs, and regression responsibilities as a feature leaf.
- Do not extract modules merely for aesthetics; extraction must reduce real
  complexity or stabilize a proven boundary.

## Acceptance Criteria

- Each architecture-debt backlog item has a leaf-level owner.
- When selected, the tree activates one executable leaf at a time.
- Behavior-preserving refactors are validated with focused and broader gates
  according to blast radius.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ARCHITECTURE-DEBT-FRONTIER`
  Status: `active`
  Goal: `Track architecture convergence and extraction backlog directions.`
  Children: `ARCHITECTURE-DEBT-FRONTIER.1`,
    `ARCHITECTURE-DEBT-FRONTIER.2`,
    `ARCHITECTURE-DEBT-FRONTIER.3`

- ID: `ARCHITECTURE-DEBT-FRONTIER.1`
  Status: `active`
  Goal: `Select the next executable architecture-debt leaf from evidence.`
  Acceptance: `One architecture item is activated, explicitly deferred, or linked to a stronger prerequisite owner.`
  Verification: `pending`
  Commit: `pending`

- ID: `ARCHITECTURE-DEBT-FRONTIER.2`
  Status: `pending`
  Goal: `Converge the direct backend path toward StructuralRTLIR-to-emitter where one bounded step is safe.`
  Acceptance: `One exact backend convergence boundary is selected, implemented or deferred, documented if user-visible, and regression-covered.`
  Verification: `pending`
  Commit: `pending`

- ID: `ARCHITECTURE-DEBT-FRONTIER.3`
  Status: `pending`
  Goal: `Extract large ISF parser/lowerer responsibilities only after stable families are identified.`
  Acceptance: `One exact extraction boundary is selected, implemented or deferred, and validated without behavior drift.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ARCHITECTURE-DEBT-FRONTIER.1` | `active` | PNT frontier selected after `BACKEND-API-VALIDATION-FRONTIER.132` exhausted the active backend/API tree. |

## Decisions

- `2026-06-05`: Keep this tree proposed while the user-selected active focus is
  Composition/type.
- `2026-06-07`: Activated after `BACKEND-API-VALIDATION-FRONTIER.132` exhausted
  the active backend/API frontier and routed PNT to architecture-debt selection.

## Open Questions

- None for the active selector leaf.

## Blockers

- None for the active selector leaf.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- |
| `2026-06-05` | `ARCHITECTURE-DEBT-FRONTIER.1` | `pending` | `pending` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ARCHITECTURE-DEBT-FRONTIER.1` | `pending` | `pending` |

## Changelog

- `2026-06-05`: Created proposed architecture-debt frontier owner tree.
