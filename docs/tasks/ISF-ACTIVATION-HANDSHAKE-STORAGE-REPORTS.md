# ISF-ACTIVATION-HANDSHAKE-STORAGE-REPORTS: Activation Handshake Storage Report Roles

## Metadata

- Tree ID: `ISF-ACTIVATION-HANDSHAKE-STORAGE-REPORTS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Expose stable schedule-report roles for generated activation start/done
handoff storage that appears in `inferred_storage[]`.

## Non-Goals

- Do not change activation syntax, generated child instantiation, or
  start/done timing.
- Do not change transaction port binding or rule-trigger payload-source roles.
- Do not classify direct non-generated child transaction handshakes.
- Do not freeze the whole schedule JSON schema.

## Acceptance Criteria

- Generated activation start handoff storage reports
  `role = activation_start_handoff` when it appears in `inferred_storage[]`.
- Generated activation done handoff storage reports
  `role = activation_done_handoff` when it appears in `inferred_storage[]`.
- Both roles are advertised in the ISF public contract and capability
  manifest storage-role family.
- Focused storage metadata coverage proves emitted generated activation
  handshake roles and widths.
- ISF spec, downstream handoff, mdBook, task tree, roadmap/live docs, changes,
  and development notes are synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-ACTIVATION-HANDSHAKE-STORAGE-REPORTS`
  Status: `done`
  Goal: `Advertise and emit generated activation start/done handoff storage roles.`
  Children: `ISF-ACTIVATION-HANDSHAKE-STORAGE-REPORTS.1`

- ID: `ISF-ACTIVATION-HANDSHAKE-STORAGE-REPORTS.1`
  Status: `done`
  Goal: `Synchronize generated activation handshake storage role metadata.`
  Acceptance: `Generated activation start/done handoff storage carries advertised roles in schedule JSON, with public contract metadata and docs synchronized.`
  Verification: `perl syntax, focused public storage metadata tests, ISF regression tier, mdBook build, and diff hygiene passed.`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-ACTIVATION-HANDSHAKE-STORAGE-REPORTS.1` | `done` | Completed; tree closed. |

## Decisions

- `2026-05-16`: Scope this tree to generated activation instance handshakes.
  Direct non-generated transaction start/done handshakes are separate because
  they do not carry generated-instance provenance.
- `2026-05-16`: Use role names that describe the generated handoff purpose
  rather than the current assignment operator shape. Some start pulses are
  combinational state outputs and therefore are not `inferred_storage[]`
  entries; this tree tags generated start handoff storage when it is present.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-ACTIVATION-HANDSHAKE-STORAGE-REPORTS.1` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1148-isf-public-storage-metadata-audit.t t/1140-isf-public-schedule-report-metadata-audit.t`; `./bin/ci-regression isf`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-ACTIVATION-HANDSHAKE-STORAGE-REPORTS.1` | `ISF-ACTIVATION-HANDSHAKE-STORAGE-REPORTS.1: report activation handshake storage roles` | `pending commit` |

## Changelog

- `2026-05-16`: Created task tree and opened the first implementation leaf.
- `2026-05-16`: Completed the first leaf and closed the tree.
