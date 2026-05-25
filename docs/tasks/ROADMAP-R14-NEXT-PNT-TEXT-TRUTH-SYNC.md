# ROADMAP-R14-NEXT-PNT-TEXT-TRUTH-SYNC: R14 Next-PNT Text Truth Synchronization

## Metadata

- Tree ID: `ROADMAP-R14-NEXT-PNT-TEXT-TRUTH-SYNC`
- Status: `done`
- Roadmap lane: `R14 roadmap maintenance`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Synchronize stale current-roadmap next-PNT wording in the R14 `Left` section
so it does not identify an old closed task tree as the current context.

## Non-Goals

- Do not change parser, scheduler, emitter, report, generated artifact, HDL,
  CLI, or public ISF behavior.
- Do not select a new feature implementation tree.
- Do not rewrite historical R14 completion notes.

## Acceptance Criteria

- The current R14 `Left` section points readers to the live active-task pointer
  at the top of `ROADMAP_STATUS.md` rather than naming a stale closed tree.
- Roadmap, task index, README, and live docs record this maintenance task.
- Focused documentation checks pass.
- The completed task is committed through `COMMIT.md`.

## Task Tree

- ID: `ROADMAP-R14-NEXT-PNT-TEXT-TRUTH-SYNC`
  Status: `done`
  Goal: `Synchronize stale next-PNT wording in the R14 roadmap section.`
  Children: `ROADMAP-R14-NEXT-PNT-TEXT-TRUTH-SYNC.1`

- ID: `ROADMAP-R14-NEXT-PNT-TEXT-TRUTH-SYNC.1`
  Status: `done`
  Goal: `Replace stale closed-tree wording with live-pointer wording.`
  Acceptance: `The R14 Left section no longer names the repeat-count source
  boundary tree as the current closed context; docs and live status are synced;
  documentation checks pass.`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `35bf9555 ROADMAP-R14-NEXT-PNT-TEXT-TRUTH-SYNC.1: sync R14 next-PNT text`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | none | `closed` | The stale next-PNT wording is synchronized. |

## Decisions

- `2026-05-22`: Keep the R14 `Left` section generic and point to the active
  task pointer at the top of `ROADMAP_STATUS.md`, because naming a specific
  recently closed tree drifts as soon as later PNT slices close.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-22` | `ROADMAP-R14-NEXT-PNT-TEXT-TRUTH-SYNC.1` | `mdbook build docs/book`; `git diff --check` | `passed; no behavior changed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ROADMAP-R14-NEXT-PNT-TEXT-TRUTH-SYNC.1` | `35bf9555 ROADMAP-R14-NEXT-PNT-TEXT-TRUTH-SYNC.1: sync R14 next-PNT text` | `removes stale closed-tree naming from the live R14 Left section` |

## Changelog

- `2026-05-22`: Created and completed the R14 next-PNT text truth sync.
