# ISF-SCHEDULE-REPORT-GOLDEN-MATRIX: Schedule Report Golden Matrix

## Metadata

- Tree ID: `ISF-SCHEDULE-REPORT-GOLDEN-MATRIX`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Maintain an executable golden fixture matrix for every advertised ISF
schedule-report branch through both in-process and CLI report paths.

## Non-Goals

- Do not flip `schedule_report_full_schema_stable` to true in the opening
  slice.
- Do not freeze the full raw schedule JSON tree beyond the advertised bounded
  key/value families.
- Do not replace focused feature tests with the matrix; focused tests remain
  the branch-level behavioral evidence.

## Acceptance Criteria

- A focused regression defines the schedule-report fixture matrix and proves
  each matrix case emits equal in-process and CLI reports.
- The regression ties advertised schedule-report families and value families to
  at least one matrix owner.
- The public contract, ISF spec, downstream handoff, mdBook, and live docs
  describe the matrix as the remaining freeze-readiness evidence.
- Validation passes for the focused regression, mdBook, and diff hygiene.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-SCHEDULE-REPORT-GOLDEN-MATRIX`
  Status: `done`
  Goal: `Add executable schedule-report golden matrix evidence.`
  Children: `ISF-SCHEDULE-REPORT-GOLDEN-MATRIX.1`

- ID: `ISF-SCHEDULE-REPORT-GOLDEN-MATRIX.1`
  Status: `done`
  Goal: `Add and document schedule-report golden matrix audit.`
  Acceptance: `The matrix covers advertised schedule-report branches through both report paths.`
  Verification: `prove -Iperl t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1255-isf-schedule-report-golden-matrix.t`; `./bin/ci-regression isf`; `git diff --check`
  Commit: `ISF-SCHEDULE-REPORT-GOLDEN-MATRIX.1: add schedule report golden matrix`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-SCHEDULE-REPORT-GOLDEN-MATRIX.1` | `done` | Closed the schedule-report golden-matrix evidence slice. |

## Decisions

- `2026-05-16`: Treat the golden matrix as a coverage/ownership audit over
  advertised bounded report families, not as a byte-for-byte fixture snapshot
  of the unfrozen full JSON tree.
- `2026-05-16`: Each matrix case must run through both
  `FSM::Scheduler::ISF->report(...)` and `./bin/fsmgen --emit-schedule-json`
  so path parity is part of the matrix rather than a separate prose claim.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-SCHEDULE-REPORT-GOLDEN-MATRIX.1` | `prove -Iperl t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1255-isf-schedule-report-golden-matrix.t` | `pass` |
| `2026-05-16` | `ISF-SCHEDULE-REPORT-GOLDEN-MATRIX.1` | `./bin/ci-regression isf` | `pass: Files=162, Tests=558; mdBook built` |
| `2026-05-16` | `ISF-SCHEDULE-REPORT-GOLDEN-MATRIX.1` | `git diff --check` | `pass` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-SCHEDULE-REPORT-GOLDEN-MATRIX.1` | `ISF-SCHEDULE-REPORT-GOLDEN-MATRIX.1: add schedule report golden matrix` | `Executable matrix and docs/contract synchronization.` |

## Changelog

- `2026-05-16`: Created task tree and opened the golden matrix audit leaf.
- `2026-05-16`: Added the executable schedule-report golden matrix audit and
  synchronized the ISF spec, downstream handoff, public contract metadata,
  mdBook, live docs, and task-tree status.
