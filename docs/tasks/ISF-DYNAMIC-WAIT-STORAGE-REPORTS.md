# ISF-DYNAMIC-WAIT-STORAGE-REPORTS: Dynamic Wait Storage Report Roles

## Metadata

- Tree ID: `ISF-DYNAMIC-WAIT-STORAGE-REPORTS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Synchronize the public schedule-report contract with the already-emitted
runtime dynamic-wait counter storage role so downstream consumers can rely on
`inferred_storage[].role = dynamic_wait_counter`.

## Non-Goals

- Do not change dynamic wait lowering, counter semantics, zero-bypass behavior,
  pending-sample behavior, or generated `.fsm`/HDL.
- Do not widen accepted dynamic wait count expressions.
- Do not freeze the whole schedule JSON schema.

## Acceptance Criteria

- `dynamic_wait_counter` is advertised in the ISF public contract and
  capability manifest storage-role family.
- Focused storage metadata coverage proves runtime dynamic wait reports emit
  only advertised storage roles.
- ISF spec, downstream handoff, mdBook, task tree, roadmap/live docs, changes,
  and development notes are synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-DYNAMIC-WAIT-STORAGE-REPORTS`
  Status: `done`
  Goal: `Advertise runtime dynamic-wait counter storage roles.`
  Children: `ISF-DYNAMIC-WAIT-STORAGE-REPORTS.1`

- ID: `ISF-DYNAMIC-WAIT-STORAGE-REPORTS.1`
  Status: `done`
  Goal: `Synchronize dynamic-wait counter storage role metadata.`
  Acceptance: `Runtime dynamic wait counter storage carries the advertised dynamic_wait_counter role in schedule JSON, with public contract metadata and docs synchronized.`
  Verification: `perl syntax, focused public storage metadata tests, ISF regression tier, mdBook build, and diff hygiene passed.`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-DYNAMIC-WAIT-STORAGE-REPORTS.1` | `done` | Completed; tree closed. |

## Decisions

- `2026-05-16`: Treat `dynamic_wait_counter` as public storage-role metadata
  because `LoweringIR` already assigns that role for runtime scalar and
  expression wait counters, and schedule reports already expose it. This slice
  synchronizes the public contract with shipped report behavior rather than
  changing lowering.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-DYNAMIC-WAIT-STORAGE-REPORTS.1` | `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1148-isf-public-storage-metadata-audit.t t/1140-isf-public-schedule-report-metadata-audit.t`; `./bin/ci-regression isf`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-DYNAMIC-WAIT-STORAGE-REPORTS.1` | `ISF-DYNAMIC-WAIT-STORAGE-REPORTS.1: advertise dynamic wait storage role` | `pending commit` |

## Changelog

- `2026-05-16`: Created task tree and opened the first contract-sync leaf.
- `2026-05-16`: Completed the first leaf and closed the tree.
