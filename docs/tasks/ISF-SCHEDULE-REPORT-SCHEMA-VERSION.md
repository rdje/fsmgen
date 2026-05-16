# ISF-SCHEDULE-REPORT-SCHEMA-VERSION: Schedule Report Schema Version

## Metadata

- Tree ID: `ISF-SCHEDULE-REPORT-SCHEMA-VERSION`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Add an explicit report-level `schema_version` to public ISF schedule JSON
reports and synchronize the public contract/docs.

## Non-Goals

- Do not freeze the whole schedule JSON schema.
- Do not change lowering semantics, generated `.fsm`, or HDL output.
- Do not change the existing `embedding.isf_public_interface.schema_version`
  contract version; this task adds a schedule-report payload version.

## Acceptance Criteria

- In-process and CLI schedule JSON reports include `schema_version: 1`.
- The ISF public contract advertises `schema_version` in the schedule-report
  top-level key family.
- Focused schedule-report tests prove the emitted value and top-level key
  family.
- ISF spec, downstream handoff, public contract doc, mdBook, roadmap/live docs,
  changes, and development notes are synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-SCHEDULE-REPORT-SCHEMA-VERSION`
  Status: `done`
  Goal: `Emit and advertise report-level schema_version.`
  Children: `ISF-SCHEDULE-REPORT-SCHEMA-VERSION.1`

- ID: `ISF-SCHEDULE-REPORT-SCHEMA-VERSION.1`
  Status: `done`
  Goal: `Add schedule-report schema_version metadata.`
  Acceptance: `Reports emit schema_version 1 and the public contract/docs advertise it.`
  Verification: `perl syntax, focused schedule-report tests, ISF regression tier, mdBook build, and diff hygiene passed.`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-SCHEDULE-REPORT-SCHEMA-VERSION.1` | `done` | Completed; tree closed. |

## Decisions

- `2026-05-16`: Use `schema_version: 1` inside the schedule report payload
  itself while keeping the existing `embedding.isf_public_interface`
  `schema_version` as the contract metadata version.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-SCHEDULE-REPORT-SCHEMA-VERSION.1` | `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1096-isf-schedule-json-report.t t/1116-isf-public-schedule-report-key-family-audit.t t/1121-isf-public-cli-schedule-report-audit.t t/1140-isf-public-schedule-report-metadata-audit.t`; `./bin/ci-regression isf`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-SCHEDULE-REPORT-SCHEMA-VERSION.1` | `ISF-SCHEDULE-REPORT-SCHEMA-VERSION.1: add report schema version` | `pending commit` |

## Changelog

- `2026-05-16`: Created task tree and opened the first implementation leaf.
- `2026-05-16`: Completed the first leaf and closed the tree.
