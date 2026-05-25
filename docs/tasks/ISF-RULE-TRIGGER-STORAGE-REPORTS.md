# ISF-RULE-TRIGGER-STORAGE-REPORTS: Rule Trigger Storage Report Roles

## Metadata

- Tree ID: `ISF-RULE-TRIGGER-STORAGE-REPORTS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Expose stable schedule-report roles for rule-trigger source pulses and
rule-trigger payload-source storage so downstream consumers can distinguish
rule-owned trigger intermediates from ordinary inferred counters.

## Non-Goals

- Do not change rule-trigger syntax, guard semantics, or activation timing.
- Do not change generated start/done handoff storage classification.
- Do not freeze the whole schedule JSON schema.

## Acceptance Criteria

- Rule-trigger source pulse storage reports `role = rule_trigger_source`.
- Rule-trigger payload-source storage reports
  `role = rule_trigger_payload_source`.
- Both roles are advertised in the ISF public contract and capability
  manifest storage-role family.
- Focused storage metadata coverage proves the emitted roles and widths.
- ISF spec, downstream handoff, mdBook, task tree, roadmap/live docs, changes,
  and development notes are synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-RULE-TRIGGER-STORAGE-REPORTS`
  Status: `done`
  Goal: `Advertise and emit rule-trigger source and payload-source storage roles.`
  Children: `ISF-RULE-TRIGGER-STORAGE-REPORTS.1`

- ID: `ISF-RULE-TRIGGER-STORAGE-REPORTS.1`
  Status: `done`
  Goal: `Synchronize rule-trigger storage role metadata.`
  Acceptance: `Rule-trigger source and payload-source storage carry advertised roles in schedule JSON, with public contract metadata and docs synchronized.`
  Verification: `perl syntax, focused public storage metadata tests, ISF regression tier, mdBook build, and diff hygiene passed.`
  Commit: `412b8f3c ISF-RULE-TRIGGER-STORAGE-REPORTS.1: report rule trigger storage roles`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-RULE-TRIGGER-STORAGE-REPORTS.1` | `done` | Completed; tree closed. |

## Decisions

- `2026-05-16`: Tag only rule-trigger source pulses and payload-source
  storage in this slice. Generated start/done handoff storage remains backlog
  until a separate compatibility rule and regression set closes that family.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-RULE-TRIGGER-STORAGE-REPORTS.1` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1148-isf-public-storage-metadata-audit.t t/1140-isf-public-schedule-report-metadata-audit.t`; `./bin/ci-regression isf`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-RULE-TRIGGER-STORAGE-REPORTS.1` | `412b8f3c ISF-RULE-TRIGGER-STORAGE-REPORTS.1: report rule trigger storage roles` | `completion commit` |

## Changelog

- `2026-05-16`: Created task tree and opened the first implementation leaf.
- `2026-05-16`: Completed the first leaf and closed the tree.
