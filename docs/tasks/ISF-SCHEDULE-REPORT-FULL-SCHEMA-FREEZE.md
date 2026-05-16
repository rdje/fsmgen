# ISF-SCHEDULE-REPORT-FULL-SCHEMA-FREEZE: Schedule Report Full Schema Freeze

## Metadata

- Tree ID: `ISF-SCHEDULE-REPORT-FULL-SCHEMA-FREEZE`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Flip the public ISF schedule-report full-schema stability flag after the
schema-version, evolution-policy, summary-boundary, and golden-matrix evidence
is in place.

## Non-Goals

- Do not freeze raw parser actor hashes.
- Do not freeze `FSM::Scheduler::ISF::LoweringIR` objects.
- Do not change schedule JSON payload content, parser behavior, scheduler
  lowering, generated `.fsm`, or HDL output beyond the public contract flag.
- Do not remove the schema-version and evolution-policy rules.

## Acceptance Criteria

- `embedding.isf_public_interface.schedule_report_full_schema_stable` is true
  in direct and manifest contract views.
- Freeze-boundary tests assert the stable flag while continuing to keep raw
  actor hashes and `LoweringIR` non-public.
- ISF spec, downstream handoff, public contract doc, mdBook, and live docs
  explain what the freeze means for schema version 1.
- Validation passes for focused contract tests, the ISF gate, mdBook, and diff
  hygiene.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-SCHEDULE-REPORT-FULL-SCHEMA-FREEZE`
  Status: `done`
  Goal: `Flip schedule-report full-schema stability flag.`
  Children: `ISF-SCHEDULE-REPORT-FULL-SCHEMA-FREEZE.1`

- ID: `ISF-SCHEDULE-REPORT-FULL-SCHEMA-FREEZE.1`
  Status: `done`
  Goal: `Freeze schedule JSON schema version 1 as public.`
  Acceptance: `The public contract flag is true and synchronized with tests and docs.`
  Verification: `prove -Iperl t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1141-isf-public-identity-flags-metadata-audit.t t/1227-isf-schedule-report-freeze-boundary.t t/1255-isf-schedule-report-golden-matrix.t`; `./bin/ci-regression isf`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-SCHEDULE-REPORT-FULL-SCHEMA-FREEZE.1: freeze schedule report schema v1`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-SCHEDULE-REPORT-FULL-SCHEMA-FREEZE.1` | `done` | Closed the final freeze flag slice. |

## Decisions

- `2026-05-16`: Freeze means the advertised schedule JSON schema version 1 is
  public and stable under the documented evolution policy. It does not make raw
  parser actors or `LoweringIR` public APIs.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-SCHEDULE-REPORT-FULL-SCHEMA-FREEZE.1` | `prove -Iperl t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1141-isf-public-identity-flags-metadata-audit.t t/1227-isf-schedule-report-freeze-boundary.t t/1255-isf-schedule-report-golden-matrix.t` | `pass` |
| `2026-05-16` | `ISF-SCHEDULE-REPORT-FULL-SCHEMA-FREEZE.1` | `./bin/ci-regression isf` | `pass: Files=162, Tests=558; mdBook built` |
| `2026-05-16` | `ISF-SCHEDULE-REPORT-FULL-SCHEMA-FREEZE.1` | `mdbook build docs/book` | `pass` |
| `2026-05-16` | `ISF-SCHEDULE-REPORT-FULL-SCHEMA-FREEZE.1` | `git diff --check` | `pass` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-SCHEDULE-REPORT-FULL-SCHEMA-FREEZE.1` | `ISF-SCHEDULE-REPORT-FULL-SCHEMA-FREEZE.1: freeze schedule report schema v1` | `Public contract flag and docs/tests synchronization.` |

## Changelog

- `2026-05-16`: Created task tree and opened the final freeze flag leaf.
- `2026-05-16`: Flipped the public schedule-report schema stability flag for
  schema version 1 and synchronized tests, docs, and live status.
