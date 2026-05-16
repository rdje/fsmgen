# ISF-FEATURE-BACKLOG-STATUS-SYNC: ISF Feature Backlog Status Truth Sync

## Metadata

- Tree ID: `ISF-FEATURE-BACKLOG-STATUS-SYNC`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Correct stale mdBook feature-backlog status labels after recently closed R14
task trees, and add a focused audit so the same truth drift is caught by
regression.

## Non-Goals

- Do not change parser, scheduler, emitter, public contract, generated `.fsm`,
  schedule JSON, or HDL behavior.
- Do not claim that backlog surfaces beyond their shipped bounded subsets are
  complete.
- Do not move active roadmap lane selection away from `R14`.

## Acceptance Criteria

- Aggregate backlog entries keep aggregate-specific backlog status text rather
  than schedule-report freeze wording.
- Schedule JSON schema freeze status matches
  `schedule_report_full_schema_stable = true` for `schema_version: 1`.
- Temporal contracts, reusable libraries, and multi-clock/CDC entries no
  longer claim pure backlog or active task-tree state when bounded surfaces
  are already shipped and their task trees are closed.
- A focused audit locks the corrected feature-backlog status labels.
- mdBook and diff hygiene checks pass.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-FEATURE-BACKLOG-STATUS-SYNC`
  Status: `done`
  Goal: `Synchronize ISF feature-backlog status truth.`
  Children: `ISF-FEATURE-BACKLOG-STATUS-SYNC.1`

- ID: `ISF-FEATURE-BACKLOG-STATUS-SYNC.1`
  Status: `done`
  Goal: `Correct stale mdBook feature-backlog status labels and audit them.`
  Acceptance: `The book labels match the current shipped/deferred boundaries and regression locks the corrected text.`
  Verification: `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-FEATURE-BACKLOG-STATUS-SYNC.1: sync ISF backlog status labels`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-FEATURE-BACKLOG-STATUS-SYNC.1` | `done` | Closed the stale status-label repair. |

## Decisions

- `2026-05-16`: Keep the correction documentation-only except for a focused
  documentation audit test; the underlying ISF behavior and public contract
  already carry the intended shipped boundaries.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-FEATURE-BACKLOG-STATUS-SYNC.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t` | `pass` |
| `2026-05-16` | `ISF-FEATURE-BACKLOG-STATUS-SYNC.1` | `mdbook build docs/book` | `pass` |
| `2026-05-16` | `ISF-FEATURE-BACKLOG-STATUS-SYNC.1` | `git diff --check` | `pass` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-FEATURE-BACKLOG-STATUS-SYNC.1` | `ISF-FEATURE-BACKLOG-STATUS-SYNC.1: sync ISF backlog status labels` | `Book status labels and audit test.` |

## Changelog

- `2026-05-16`: Created and closed the task tree for a focused book status
  truth repair.
