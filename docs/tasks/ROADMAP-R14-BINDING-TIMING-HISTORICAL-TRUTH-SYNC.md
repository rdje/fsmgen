# ROADMAP-R14-BINDING-TIMING-HISTORICAL-TRUTH-SYNC: Binding Timing History Truth Sync

## Metadata

- Tree ID: `ROADMAP-R14-BINDING-TIMING-HISTORICAL-TRUTH-SYNC`
- Status: `done`
- Roadmap lane: `R14 roadmap maintenance`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Synchronize older recovery notes that still describe explicit
snapshot-vs-live binding timing syntax as entirely deferred after current
timing assertions and authored timing metadata shipped.

## Non-Goals

- Do not change parser behavior, scheduler lowering, generated `.fsm`, HDL,
  schedule-report payloads, public contract code, or runtime behavior.
- Do not claim behavior-changing snapshot/live timing conversion is shipped.
- Do not rewrite the historical sequence of earlier slices beyond noting the
  later shipped state.

## Acceptance Criteria

- Historical notes distinguish shipped current-timing `(timing snapshot|live)`
  assertions and `authored_timing_mode` metadata from still-deferred
  behavior-changing timing conversion.
- The task tree, roadmap status, live docs, and change history record this as
  documentation-only truth synchronization.
- Focused public-doc/book validation passes.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ROADMAP-R14-BINDING-TIMING-HISTORICAL-TRUTH-SYNC`
  Status: `done`
  Goal: `Synchronize stale binding-timing history.`
  Children: `ROADMAP-R14-BINDING-TIMING-HISTORICAL-TRUTH-SYNC.1`

- ID: `ROADMAP-R14-BINDING-TIMING-HISTORICAL-TRUTH-SYNC.1`
  Status: `done`
  Goal: `Sync snapshot/live timing history with later current-timing syntax.`
  Acceptance: `Older notes no longer imply all snapshot/live timing syntax is deferred.`
  Verification: `stale timing wording grep; focused live-doc/book audits; mdBook build; git diff --check`
  Commit: `ROADMAP-R14-BINDING-TIMING-HISTORY-SYNC.1: sync binding timing history`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| `_None_` | `_None_` | `_None_` | Tree closed. |

## Decisions

- `2026-05-25`: Keep this docs-only. Current-timing `(timing snapshot|live)`
  assertions and authored timing metadata are shipped; behavior-changing
  snapshot/live timing conversion remains deferred.

## Open Questions

- None for this truth-sync slice.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ROADMAP-R14-BINDING-TIMING-HISTORICAL-TRUTH-SYNC.1` | stale timing wording grep confirmed remaining matches are historical task non-goals or explicit behavior-conversion deferrals; `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `pass` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ROADMAP-R14-BINDING-TIMING-HISTORICAL-TRUTH-SYNC.1` | `ROADMAP-R14-BINDING-TIMING-HISTORY-SYNC.1: sync binding timing history` | `completion commit` |

## Changelog

- `2026-05-25`: Created active task tree for binding timing historical truth
  synchronization.
- `2026-05-25`: Completed truth synchronization; older notes now distinguish
  shipped current-timing assertions and authored timing metadata from deferred
  behavior-changing timing conversion.
