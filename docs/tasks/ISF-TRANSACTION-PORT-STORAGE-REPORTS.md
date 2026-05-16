# ISF-TRANSACTION-PORT-STORAGE-REPORTS: Transaction Port Storage Report Roles

## Metadata

- Tree ID: `ISF-TRANSACTION-PORT-STORAGE-REPORTS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Synchronize the public schedule-report contract with transaction-local port
storage roles that schedule reports already emit for declared transaction
ports materialized in the scheduled `.fsm` review artifact.

## Non-Goals

- Do not change transaction port syntax, binding syntax, port timing, or
  generated `.fsm`/HDL.
- Do not widen transaction port direction or expression semantics.
- Do not freeze the whole schedule JSON schema.

## Acceptance Criteria

- `transaction_port` is advertised in the ISF public contract and capability
  manifest storage-role family.
- Focused storage metadata coverage proves a transaction-local port storage
  report emits the advertised role and known width.
- ISF spec, downstream handoff, mdBook, task tree, roadmap/live docs, changes,
  and development notes are synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-TRANSACTION-PORT-STORAGE-REPORTS`
  Status: `done`
  Goal: `Advertise transaction-local port storage roles.`
  Children: `ISF-TRANSACTION-PORT-STORAGE-REPORTS.1`

- ID: `ISF-TRANSACTION-PORT-STORAGE-REPORTS.1`
  Status: `done`
  Goal: `Synchronize transaction-local port storage role metadata.`
  Acceptance: `Transaction-local port storage carries the advertised transaction_port role in schedule JSON, with public contract metadata and docs synchronized.`
  Verification: `perl syntax, focused public storage metadata tests, ISF regression tier, mdBook build, and diff hygiene passed.`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-TRANSACTION-PORT-STORAGE-REPORTS.1` | `done` | Completed; tree closed. |

## Decisions

- `2026-05-16`: Advertise `transaction_port` because transaction-local port
  storage already appears in public `inferred_storage[]` reports when the
  port is materialized by scheduled assignments. This is contract sync, not a
  change to transaction port lowering.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-TRANSACTION-PORT-STORAGE-REPORTS.1` | `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1148-isf-public-storage-metadata-audit.t t/1140-isf-public-schedule-report-metadata-audit.t`; `./bin/ci-regression isf`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-TRANSACTION-PORT-STORAGE-REPORTS.1` | `ISF-TRANSACTION-PORT-STORAGE-REPORTS.1: advertise transaction port storage role` | `pending commit` |

## Changelog

- `2026-05-16`: Created task tree and opened the first contract-sync leaf.
- `2026-05-16`: Completed the first leaf and closed the tree.
