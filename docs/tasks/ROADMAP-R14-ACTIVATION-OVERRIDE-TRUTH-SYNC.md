# ROADMAP-R14-ACTIVATION-OVERRIDE-TRUTH-SYNC: Activation Override Roadmap Truth Sync

## Metadata

- Tree ID: `ROADMAP-R14-ACTIVATION-OVERRIDE-TRUTH-SYNC`
- Status: `done`
- Roadmap lane: `R14 roadmap maintenance`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Synchronize the lower R14 roadmap detail and task-tree objective coverage after
`ISF-CONTRACT-ACTIVATION-OVERRIDE-WINDOWS.2` shipped activation-site override
diagnostics for generated child temporal contract-window parameters.

## Non-Goals

- Do not change parser, scheduler, generated `.fsm`, HDL, schedule-report, or
  public API behavior.
- Do not reopen activation-site override-specialized temporal monitor
  lowering.
- Do not edit mdBook behavior prose except if a documentation audit requires
  it.

## Acceptance Criteria

- The R14 detailed `Done` list records the shipped activation override
  contract-window diagnostic behavior.
- The R14 ISF objective coverage table points the diagnostic objective family
  at `ISF-CONTRACT-ACTIVATION-OVERRIDE-WINDOWS`.
- The README task index, task-tree index, roadmap, and live docs are
  synchronized.
- Doc-focused validation passes.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ROADMAP-R14-ACTIVATION-OVERRIDE-TRUTH-SYNC`
  Status: `done`
  Goal: `Synchronize R14 roadmap/task-tree coverage for shipped activation override contract-window diagnostics.`
  Children: `ROADMAP-R14-ACTIVATION-OVERRIDE-TRUTH-SYNC.1`

- ID: `ROADMAP-R14-ACTIVATION-OVERRIDE-TRUTH-SYNC.1`
  Status: `done`
  Goal: `Sync R14 roadmap detail and objective coverage.`
  Acceptance: `Lower R14 done detail and task-tree objective coverage include
  the shipped activation override diagnostic tree without claiming
  override-specialized monitor lowering.`
  Verification: `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t`; `git diff --check`
  Commit: `b249841f ROADMAP-R14-ACTIVATION-OVERRIDE-TRUTH-SYNC.1: sync activation override roadmap coverage`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `ROADMAP-R14-ACTIVATION-OVERRIDE-TRUTH-SYNC.1` is a one-leaf documentation truth-sync slice. |

## Decisions

- `2026-05-25`: Keep this slice documentation-only. The behavior was already
  implemented and validated under
  `ISF-CONTRACT-ACTIVATION-OVERRIDE-WINDOWS.2`; this tree only fixes the
  roadmap/task-tree coverage ledger.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ROADMAP-R14-ACTIVATION-OVERRIDE-TRUTH-SYNC.1` | `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t`; `git diff --check` | `passed`; audits `Files=3, Tests=364` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ROADMAP-R14-ACTIVATION-OVERRIDE-TRUTH-SYNC.1` | `b249841f ROADMAP-R14-ACTIVATION-OVERRIDE-TRUTH-SYNC.1: sync activation override roadmap coverage` | Documentation truth-sync slice; no behavior change. |

## Changelog

- `2026-05-25`: Created and completed the one-leaf documentation truth-sync
  tree.
