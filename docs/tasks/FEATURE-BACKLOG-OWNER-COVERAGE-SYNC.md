# FEATURE-BACKLOG-OWNER-COVERAGE-SYNC: Feature Backlog Owner Coverage Sync

## Metadata

- Tree ID: `FEATURE-BACKLOG-OWNER-COVERAGE-SYNC`
- Status: `active`
- Roadmap lane: `roadmap maintenance`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Make the mdBook feature backlog and repo-local task-tree owner coverage agree
for broad backlog sections before any behavior-bearing follow-up work is
selected.

## Non-Goals

- Do not implement any backlog feature.
- Do not reopen closed historical task trees.
- Do not change parser, scheduler, emitter, report, generated artifact, HDL,
  CLI, or public API behavior.
- Do not decide policy for broad backlog items whose implementation needs
  future design work.

## Acceptance Criteria

- The task tree is selected before any backlog-owner coverage edits.
- The task-tree owner coverage table and mdBook backlog truth are audited for
  broad backlog items that are not represented by an active, completed, or
  explicitly future-owner task tree.
- Any documentation edits make the current owner/needs-new-tree status
  explicit without implying that closed trees own future work.
- Focused documentation audits and `mdbook build docs/book` pass.
- `git diff --check` passes.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `FEATURE-BACKLOG-OWNER-COVERAGE-SYNC`
  Status: `active`
  Goal: `Synchronize broad feature-backlog owner coverage with task-tree tracking`
  Children: `FEATURE-BACKLOG-OWNER-COVERAGE-SYNC.1`,
  `FEATURE-BACKLOG-OWNER-COVERAGE-SYNC.2`

- ID: `FEATURE-BACKLOG-OWNER-COVERAGE-SYNC.1`
  Status: `done`
  Goal: `Select the broad feature-backlog owner coverage maintenance slice`
  Acceptance: `Create the active task tree, record the coverage gap, set the
  implementation frontier, and update roadmap/live docs without behavior
  changes`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `pending this commit`

- ID: `FEATURE-BACKLOG-OWNER-COVERAGE-SYNC.2`
  Status: `pending`
  Goal: `Audit and synchronize broad feature-backlog owner coverage`
  Acceptance: `The task-tree owner coverage table and mdBook backlog agree on
  broad backlog owner status, future-owner needs are explicit, and focused
  audits prevent the drift from returning`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `FEATURE-BACKLOG-OWNER-COVERAGE-SYNC.2` | `pending` | `The broad feature-backlog owner coverage gap is selected and owned.` |

## Decisions

- `2026-05-24`: Treat this as roadmap maintenance because it changes tracking
  truth, not compiler behavior.
- `2026-05-24`: Keep the first implementation leaf documentation/audit only.
  Any behavior-bearing backlog item still needs its own task tree and user-
  visible acceptance criteria before code changes.

## Open Questions

- None for the selection leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `FEATURE-BACKLOG-OWNER-COVERAGE-SYNC.1` | `prove -Iperl t/1303-isf-public-live-book-paths-audit.t t/1250-isf-spec-focused-test-index-audit.t` | `passed: Files=2, Tests=25` |
| `2026-05-24` | `FEATURE-BACKLOG-OWNER-COVERAGE-SYNC.1` | `mdbook build docs/book` | `passed` |
| `2026-05-24` | `FEATURE-BACKLOG-OWNER-COVERAGE-SYNC.1` | `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `FEATURE-BACKLOG-OWNER-COVERAGE-SYNC.1` | `pending this commit: FEATURE-BACKLOG-OWNER-COVERAGE-SYNC.1: select backlog owner coverage sync` | `selection slice` |
| `FEATURE-BACKLOG-OWNER-COVERAGE-SYNC.2` | `pending` | `owner coverage sync slice` |

## Changelog

- `2026-05-24`: Created and activated the task tree.
