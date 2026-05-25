# ISF-SCHEDULE-REPORT-STORAGE-ROLES: Additive Schedule-Report Storage Roles

## Metadata

- Tree ID: `ISF-SCHEDULE-REPORT-STORAGE-ROLES`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Expose the next bounded set of stable scheduler-owned storage roles in
schedule JSON so downstream tooling can classify generated ATL trigger
handoffs and scheduler timeout-status storage without parsing generated names.

## Non-Goals

- Do not change scheduled `.fsm` behavior, HDL behavior, state topology, or
  timeout semantics.
- Do not freeze private `LoweringIR` hashes or raw state assignment lists as a
  public interface.
- Do not assign roles to storage whose scheduler purpose is still ambiguous.

## Acceptance Criteria

- `inferred_storage[].role` includes stable additive roles for generated ATL
  trigger-start handoffs and the global scheduler timeout/error status latch.
- The public contract advertises the new role values, and public report
  metadata tests cover them.
- `docs/ISF_SPEC.md`, `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md`,
  `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md`, and the mdBook explain the new
  role values and their additive semantics.
- Focused validation passes, broader ISF validation runs because the schedule
  report public surface changes, and the leaf is committed through
  `COMMIT.md`.

## Task Tree

- ID: `ISF-SCHEDULE-REPORT-STORAGE-ROLES`
  Status: `done`
  Goal: `Add the next bounded public storage-role metadata slice.`
  Children: `ISF-SCHEDULE-REPORT-STORAGE-ROLES.1`

- ID: `ISF-SCHEDULE-REPORT-STORAGE-ROLES.1`
  Status: `done`
  Goal: `Advertise ATL trigger-start handoff and scheduler timeout-status storage roles.`
  Acceptance: `Reports emit the new roles for covered fixtures, public metadata advertises them, docs/book are synchronized, validation passes, and the slice is committed.`
  Verification: `syntax checks; focused public-contract/report/docs tests Files=10, Tests=385; focused schedule/ATL tests Files=4, Tests=11; focused burst fixture Files=1, Tests=3; ci-regression isf --no-book Files=275, Tests=1755; mdbook build docs/book; git diff --check`
  Commit: `ISF-SCHEDULE-REPORT-STORAGE-ROLES.1: add schedule report storage roles`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `ISF-SCHEDULE-REPORT-STORAGE-ROLES.1` shipped ATL trigger-start handoff and scheduler timeout-status storage roles. |

## Decisions

- `2026-05-25`: Keep the slice metadata-only. Downstream users get stable
  role labels, while generated `.fsm` and HDL behavior remain unchanged.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ISF-SCHEDULE-REPORT-STORAGE-ROLES.1` | syntax checks; focused public-contract/report/docs tests; focused schedule/ATL tests; focused burst fixture; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | passed; focused public/docs `Files=10, Tests=385`; focused schedule/ATL `Files=4, Tests=11`; focused burst `Files=1, Tests=3`; broad ISF `Files=275, Tests=1755` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-SCHEDULE-REPORT-STORAGE-ROLES.1` | `ISF-SCHEDULE-REPORT-STORAGE-ROLES.1: add schedule report storage roles` | task-scoped commit subject |

## Changelog

- `2026-05-25`: Created and activated task tree.
- `2026-05-25`: Implemented and documented additive storage-role metadata;
  closed the tree.
