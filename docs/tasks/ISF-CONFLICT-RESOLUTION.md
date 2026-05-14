# ISF-CONFLICTS: Rule And Transaction Output Conflict Semantics

## Metadata

- Tree ID: `ISF-CONFLICTS`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-14`
- Last updated: `2026-05-14`
- Owner: repo-local workflow

## Goal

Make ISF same-cycle conflict behavior precise, implementable, documented, and
regression-backed when multiple rules, transactions, drive calls, completion
pulses, or generated helper paths can target the same downstream signal or
transaction start input.

## Non-Goals

- Do not redesign the `.fsm` assignment model.
- Do not implement broad resource scheduling unless it is needed to close a
  concrete conflict semantic.
- Do not stabilize new public API surfaces beyond what the shipped conflict
  behavior requires.
- Do not hide incompatible same-cycle drives by choosing an arbitrary winner.

## Acceptance Criteria

- Conflict domains are explicitly defined for ISF-authored outputs, generated
  storage, transaction starts, delayed pulses, and named-drive expansions.
- Compatible fan-in cases are either merged deterministically or documented as
  intentionally rejected.
- Incompatible same-cycle drive cases fail with targeted diagnostics before
  misleading scheduled `.fsm` or HDL is treated as valid.
- Priority/resource metadata interaction is either implemented for the covered
  domains or explicitly deferred with the consequence documented.
- The scheduler/emitter behavior, ISF spec, public interface contract, mdBook,
  roadmap/live docs, and focused regressions agree.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-CONFLICTS`
  Status: `active`
  Goal: `Define and ship ISF same-cycle output conflict semantics.`
  Children: `ISF-CONFLICTS.1`, `ISF-CONFLICTS.2`, `ISF-CONFLICTS.3`,
  `ISF-CONFLICTS.4`, `ISF-CONFLICTS.5`, `ISF-CONFLICTS.6`,
  `ISF-CONFLICTS.7`

- ID: `ISF-CONFLICTS.1`
  Status: `pending`
  Goal: `Inventory current conflict behavior and define conflict domains.`
  Acceptance: `Existing scheduler/emitter behavior is inspected, current
  accepted/rejected multi-drive shapes are listed, and conflict domains are
  named in this task file before implementation work starts.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-CONFLICTS.2`
  Status: `pending`
  Goal: `Specify deterministic merge policy for compatible fan-in.`
  Acceptance: `The task file and live docs state which same-target cases merge
  by OR/fan-in, which share generated helper signals, and which preserve
  existing rule-trigger fan-in behavior.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-CONFLICTS.3`
  Status: `pending`
  Goal: `Specify fail-closed and priority policy for incompatible drives.`
  Acceptance: `The task file records the policy for incompatible writes,
  missing priority, declared priority, and deferred resource arbitration.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-CONFLICTS.4`
  Status: `pending`
  Goal: `Implement scheduler/emitter conflict tracking.`
  Acceptance: `The implementation can distinguish compatible fan-in from
  incompatible same-cycle drive conflicts without relying on text-order
  accidents in emitted `.fsm`.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-CONFLICTS.5`
  Status: `pending`
  Goal: `Add diagnostics and schedule-report projection.`
  Acceptance: `Rejected conflict cases report targeted diagnostics, and
  accepted conflict/fan-in cases are visible in bounded schedule-report
  metadata where useful for downstream consumers.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-CONFLICTS.6`
  Status: `pending`
  Goal: `Add focused regressions and at least one realistic fixture.`
  Acceptance: `Tests cover accepted fan-in, rejected incompatible drives, and
  a realistic ISF fixture that would have been ambiguous without the new
  conflict model.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-CONFLICTS.7`
  Status: `pending`
  Goal: `Synchronize user-facing documentation and close the tree.`
  Acceptance: `The ISF spec, public interface contract, mdBook, roadmap,
  MEMORY, CHANGES, DEVELOPMENT_NOTES, and LIVE_ACHIEVEMENT_STATUS describe the
  shipped conflict behavior and remaining limitations.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-CONFLICTS.1` | `pending` | The implementation policy must be based on the current scheduler/emitter behavior and exact conflict-domain vocabulary. |

## Decisions

- `2026-05-14`: The conflict-resolution work will be tracked as a task tree
  because it is expected to branch into policy, implementation, diagnostics,
  tests, and documentation subtasks.
- `2026-05-14`: The existing rule-trigger fan-in implementation remains a
  compatible fan-in precedent, not a license to silently merge every same-target
  drive.

## Open Questions

- Which same-target assignment families are compatible by construction, and
  which require explicit priority or rejection?
- Should priority metadata be enforced in this tree, or should this tree first
  fail closed for conflicts that require priority semantics?
- Which schedule-report fields are necessary for downstream consumers without
  prematurely freezing a broad conflict-report API?

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-14` | `ISF-CONFLICTS` | `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-CONFLICTS` | `Docs: formalize repo-local task tree` | Initial tree creation is part of the repo-local task-tree workflow slice. |

## Changelog

- `2026-05-14`: Created the active ISF conflict-resolution task tree.
