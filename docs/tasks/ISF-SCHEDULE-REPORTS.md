# ISF-SCHEDULE-REPORTS: Schedule Report Storage Classes And Schema Stabilization

## Metadata

- Tree ID: `ISF-SCHEDULE-REPORTS`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-14`
- Last updated: `2026-05-14`
- Owner: repo-local workflow

## Goal

Make the ISF schedule report more useful and stable by improving inferred
storage classifications, adding bounded metadata required by shipped features,
and defining the path from current bounded key families toward any fully frozen
schedule JSON schema.

## Non-Goals

- Do not freeze the whole schedule JSON tree until every advertised field has
  owner, tests, and compatibility rules.
- Do not add report fields that are not backed by scheduler truth or a shipped
  feature.
- Do not replace normalized semantic JSON or the broader embedding contracts.

## Acceptance Criteria

- Current schedule-report keys, bounded public key families, and storage
  classifications are inventoried.
- Richer storage classes are specified and implemented for agreed scheduler
  storage families.
- Feature-driven report additions from other ISF trees have documented owners
  and public-contract treatment.
- A schema-freeze readiness checklist exists, with explicit blockers for any
  not-yet-frozen branches.
- Tests cover in-process and CLI schedule report behavior.
- ISF public interface contract, manifest metadata, ISF spec, mdBook, roadmap,
  and live docs agree.

## Task Tree

- ID: `ISF-SCHEDULE-REPORTS`
  Status: `active`
  Goal: `Improve schedule-report storage classes and define schema stabilization.`
  Children: `ISF-SCHEDULE-REPORTS.1`, `ISF-SCHEDULE-REPORTS.2`,
  `ISF-SCHEDULE-REPORTS.3`, `ISF-SCHEDULE-REPORTS.4`,
  `ISF-SCHEDULE-REPORTS.5`

- ID: `ISF-SCHEDULE-REPORTS.1`
  Status: `pending`
  Goal: `Inventory current schedule-report shape and public contract boundaries.`
  Acceptance: `The task file lists current top-level keys, bounded key
  families, storage metadata, feature-owned report fields, and non-frozen
  branches.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-SCHEDULE-REPORTS.2`
  Status: `pending`
  Goal: `Specify richer inferred-storage class taxonomy.`
  Acceptance: `The tree records storage classes, required source evidence,
  report keys, compatibility rules, and deferred classes.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-SCHEDULE-REPORTS.3`
  Status: `pending`
  Goal: `Implement first richer storage-class report slice.`
  Acceptance: `The selected storage families report the new bounded class
  metadata through in-process and CLI schedule JSON.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-SCHEDULE-REPORTS.4`
  Status: `pending`
  Goal: `Define schedule JSON schema-freeze readiness plan.`
  Acceptance: `The tree and public contract identify what is frozen, what is
  bounded-but-not-frozen, what remains raw/internal, and what blocks full
  schema freeze.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-SCHEDULE-REPORTS.5`
  Status: `pending`
  Goal: `Add tests and synchronize docs/contracts.`
  Acceptance: `Tests cover report metadata, manifest/public contract claims,
  CLI/in-process parity, and synchronized user-facing docs.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-SCHEDULE-REPORTS.1` | `pending` | The current bounded report contract must be inventoried before adding or freezing report fields. |

## Decisions

- `2026-05-14`: Schedule-report stabilization remains feature-driven. Whole
  schema freeze is tracked, but not assumed, by this tree.

## Open Questions

- Which richer storage classes are immediately useful to downstream consumers?
- Should feature-owned report additions be centralized here or completed inside
  each feature tree with this tree acting as the schema index?

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-14` | `ISF-SCHEDULE-REPORTS` | `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-SCHEDULE-REPORTS` | `R14: map ISF objectives to task trees` | Initial tree creation belongs to the ISF objective task-tree coverage slice. |

## Changelog

- `2026-05-14`: Created the active ISF schedule-report task tree.
