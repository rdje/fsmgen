# ISF-ATL-FRONTIER-TRUTH-SYNC: ATL Frontier Truth Synchronization

## Metadata

- Tree ID: `ISF-ATL-FRONTIER-TRUTH-SYNC`
- Status: `done`
- Roadmap lane: `R14 roadmap maintenance`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Synchronize stale Actor Transfer Level task-tree frontier prose after the ATL
implementation tree was exhausted, so the task ledger no longer points at
completed leaves as if they were still selectable frontier work.

## Non-Goals

- Do not change parser, scheduler, emitter, report, generated artifact, HDL,
  CLI, or public ISF behavior.
- Do not reopen the closed ATL implementation tree or select new ATL runtime
  semantics.
- Do not reclassify deferred ATL route mux/storage, fan-in/fan-out,
  ready/backpressure, payload, CDC, recursive-network, or permanent-group
  behavior as shipped.
- Do not edit the mdBook unless the user-facing shipped/deferred behavior
  wording is found to be stale.

## Acceptance Criteria

- The stale `ISF-ACTOR-NETWORK-ORCHESTRATION` current-frontier table records a
  closed frontier instead of listing completed leaves as next work.
- The ATL task metadata accurately reflects its latest update date and closed
  status.
- Roadmap, task index, README, and live docs identify this truth-sync task as
  the active maintenance owner while it is in progress, then close it.
- Focused documentation checks pass.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-ATL-FRONTIER-TRUTH-SYNC`
  Status: `done`
  Goal: `Correct stale ATL frontier truth after tree exhaustion.`
  Children: `ISF-ATL-FRONTIER-TRUTH-SYNC.1`,
  `ISF-ATL-FRONTIER-TRUTH-SYNC.2`

- ID: `ISF-ATL-FRONTIER-TRUTH-SYNC.1`
  Status: `done`
  Goal: `Select ATL frontier truth synchronization.`
  Acceptance: `Create the active maintenance tree, identify the stale closed
  ATL frontier wording, and update roadmap/live docs without behavior
  changes.`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `266ffc99 ISF-ATL-FRONTIER-TRUTH-SYNC.1: select ATL frontier truth sync`

- ID: `ISF-ATL-FRONTIER-TRUTH-SYNC.2`
  Status: `done`
  Goal: `Synchronize the closed ATL frontier.`
  Acceptance: `The ATL task tree reports a closed frontier and current
  metadata; roadmap, task index, README, and live docs close this maintenance
  tree; focused documentation checks pass.`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `pending commit`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | none | `closed` | The stale ATL current-frontier table is synchronized. |

## Decisions

- `2026-05-22`: Select a documentation-truth maintenance slice. The global
  task index already marks the ATL tree as complete, but the ATL task file's
  own current-frontier table still names completed leaves, which can mislead
  the next PNT selection.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-22` | `ISF-ATL-FRONTIER-TRUTH-SYNC.1` | `mdbook build docs/book`; `git diff --check` | `selection docs passed; no behavior changed` |
| `2026-05-22` | `ISF-ATL-FRONTIER-TRUTH-SYNC.2` | `mdbook build docs/book`; `git diff --check` | `frontier truth-sync docs passed; no behavior changed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-ATL-FRONTIER-TRUTH-SYNC.1` | `266ffc99 ISF-ATL-FRONTIER-TRUTH-SYNC.1: select ATL frontier truth sync` | `selects stale closed-frontier synchronization for the exhausted ATL tree` |
| `ISF-ATL-FRONTIER-TRUTH-SYNC.2` | `this commit: ISF-ATL-FRONTIER-TRUTH-SYNC.2: sync ATL frontier truth` | `syncs the exhausted ATL tree's current frontier and closes this maintenance tree` |

## Changelog

- `2026-05-22`: Created task tree and selected ATL frontier truth
  synchronization.
- `2026-05-22`: Synchronized the closed ATL current frontier and closed this
  maintenance tree.
