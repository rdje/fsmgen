# ISF-SCHEDULE-REPORT-SUMMARY-BOUNDARY: Schedule Report Summary Boundary

## Metadata

- Tree ID: `ISF-SCHEDULE-REPORT-SUMMARY-BOUNDARY`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Decide and document the public/private boundary for assignment provenance and
multi-file child summaries in ISF schedule reports.

## Non-Goals

- Do not add raw assignment provenance payloads to schedule JSON.
- Do not add recursive child schedule reports to the parent report.
- Do not change generated `.fsm`, schedule JSON payloads, or HDL output.
- Do not flip `schedule_report_full_schema_stable` to true.

## Acceptance Criteria

- ISF spec, downstream handoff, public contract doc, and mdBook state that raw
  assignment provenance remains private while bounded public summaries remain
  the supported review surface.
- The same docs state that multi-file child details stay bounded to existing
  `generated_composition`, `library_uses`, `clock_domains[]`, and public
  `lower(...)` file-map surfaces rather than recursive child report dumps.
- Whole-schema freeze blockers remove the assignment-provenance/multi-file
  child summary decision while keeping the golden fixture matrix blocker.
- mdBook and diff hygiene validation pass.
- Live docs, task tree, changes, and development notes are synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-SCHEDULE-REPORT-SUMMARY-BOUNDARY`
  Status: `done`
  Goal: `Document schedule-report assignment and child-summary boundary.`
  Children: `ISF-SCHEDULE-REPORT-SUMMARY-BOUNDARY.1`

- ID: `ISF-SCHEDULE-REPORT-SUMMARY-BOUNDARY.1`
  Status: `done`
  Goal: `Document public/private report summary boundary.`
  Acceptance: `The public docs state what remains private and which bounded summaries are the public substitute.`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-SCHEDULE-REPORT-SUMMARY-BOUNDARY.1: document report summary boundary`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-SCHEDULE-REPORT-SUMMARY-BOUNDARY.1` | `done` | Closed the schedule-report summary-boundary decision. |

## Decisions

- `2026-05-16`: Keep raw assignment provenance and recursive child reports
  private. Public reports expose bounded summaries for conflict/fan-in,
  priority/resource decisions, generated composition, library uses, and
  clock-domain child artifacts.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-SCHEDULE-REPORT-SUMMARY-BOUNDARY.1` | `mdbook build docs/book`; `git diff --check` | `pass` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-SCHEDULE-REPORT-SUMMARY-BOUNDARY.1` | `ISF-SCHEDULE-REPORT-SUMMARY-BOUNDARY.1: document report summary boundary` | `Documentation-policy slice.` |

## Changelog

- `2026-05-16`: Created task tree and opened the first documentation leaf.
- `2026-05-16`: Documented the private raw-provenance and recursive child
  report boundary across the ISF spec, downstream handoff, public contract doc,
  mdBook, and live docs.
