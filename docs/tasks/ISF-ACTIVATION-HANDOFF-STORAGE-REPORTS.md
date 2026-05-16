# ISF-ACTIVATION-HANDOFF-STORAGE-REPORTS: Activation Handoff Storage Report Roles

## Metadata

- Tree ID: `ISF-ACTIVATION-HANDOFF-STORAGE-REPORTS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Synchronize the public schedule-report contract with generated activation
handoff storage roles that schedule reports already emit for generated
transaction port bindings and rule-trigger completion observation.

## Non-Goals

- Do not change generated activation lowering, generated top wiring, port
  binding timing, rule-trigger timing, or generated `.fsm`/HDL.
- Do not add roles for every generated start/done or payload source signal.
- Do not freeze the whole schedule JSON schema.

## Acceptance Criteria

- `transaction_port_binding` and `trigger_done_observe` are advertised in the
  ISF public contract and capability manifest storage-role family.
- Focused storage metadata coverage proves generated activation reports emit
  only advertised storage roles for those surfaces.
- ISF spec, downstream handoff, mdBook, task tree, roadmap/live docs, changes,
  and development notes are synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-ACTIVATION-HANDOFF-STORAGE-REPORTS`
  Status: `done`
  Goal: `Advertise generated activation handoff storage roles.`
  Children: `ISF-ACTIVATION-HANDOFF-STORAGE-REPORTS.1`

- ID: `ISF-ACTIVATION-HANDOFF-STORAGE-REPORTS.1`
  Status: `done`
  Goal: `Synchronize generated activation handoff storage role metadata.`
  Acceptance: `Generated transaction-port handoff storage and rule-trigger done-observe storage carry advertised roles in schedule JSON, with public contract metadata and docs synchronized.`
  Verification: `perl syntax, focused public storage metadata tests, ISF regression tier, mdBook build, and diff hygiene passed.`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-ACTIVATION-HANDOFF-STORAGE-REPORTS.1` | `done` | Completed; tree closed. |

## Decisions

- `2026-05-16`: Advertise only the roles already emitted by schedule reports:
  `transaction_port_binding` for generated activation transaction-port
  handoff storage and `trigger_done_observe` for generated rule-trigger done
  observation. Other generated start/done/payload source roles remain
  unpromised until explicitly assigned and covered.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-ACTIVATION-HANDOFF-STORAGE-REPORTS.1` | `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1148-isf-public-storage-metadata-audit.t t/1140-isf-public-schedule-report-metadata-audit.t`; `./bin/ci-regression isf`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-ACTIVATION-HANDOFF-STORAGE-REPORTS.1` | `ISF-ACTIVATION-HANDOFF-STORAGE-REPORTS.1: advertise activation handoff storage roles` | `pending commit` |

## Changelog

- `2026-05-16`: Created task tree and opened the first contract-sync leaf.
- `2026-05-16`: Completed the first leaf and closed the tree.
