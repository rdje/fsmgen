# ISF-BACKLOG-OWNER-TRUTH-SYNC: Backlog Task-Tree Owner Truth Sync

## Metadata

- Tree ID: `ISF-BACKLOG-OWNER-TRUTH-SYNC`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Keep the mdBook feature backlog truthful about task-tree ownership for
remaining ISF backlog items after the original repeat-body activation and ATL
task trees have closed.

## Non-Goals

- Do not reopen closed task trees.
- Do not change parser, scheduler, emitter, report, generated artifact, or
  HDL behavior.
- Do not select the next behavior-bearing repeat or ATL implementation.
- Do not remove links to historical task trees that explain shipped behavior.

## Acceptance Criteria

- The book no longer names closed task trees as current owners for remaining
  backlog behavior.
- Historical task-tree links remain available and are clearly distinguished
  from future owner leaves that still need to be created.
- A focused audit prevents closed task-tree wording from being reintroduced in
  the book-facing backlog.
- Live docs and roadmap status identify the selected maintenance slice and
  its verification.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-BACKLOG-OWNER-TRUTH-SYNC`
  Status: `active`
  Goal: `Synchronize book-facing backlog task-tree ownership wording.`
  Children: `ISF-BACKLOG-OWNER-TRUTH-SYNC.1`,
  `ISF-BACKLOG-OWNER-TRUTH-SYNC.2`

- ID: `ISF-BACKLOG-OWNER-TRUTH-SYNC.1`
  Status: `done`
  Goal: `Select the backlog owner truth-sync slice.`
  Acceptance: `Create the active task tree, document the exact stale-owner
  wording problem, set the implementation frontier, and update roadmap/live
  docs without behavior changes.`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `pending commit`

- ID: `ISF-BACKLOG-OWNER-TRUTH-SYNC.2`
  Status: `pending`
  Goal: `Sync the mdBook backlog owner wording and add audit coverage.`
  Acceptance: `The repeat-body child activation and ATL backlog sections keep
  historical links but say future behavior changes need new task-tree leaves;
  the focused book audit rejects current-owner wording that points at closed
  task trees; mdBook, focused audits, and diff checks pass.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-BACKLOG-OWNER-TRUTH-SYNC.2` | `pending` | The selection leaf is complete; the book/audit truth sync is the executable frontier. |

## Decisions

- `2026-05-22`: Treat closed repeat-body activation and ATL task trees as
  historical evidence, not current owners for remaining backlog. This keeps
  the book truthful while preserving review links to the shipped slices.
- `2026-05-22`: Add audit coverage rather than relying on prose discipline.
  The user-facing book is the review surface, so stale ownership wording must
  fail mechanically.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-22` | `ISF-BACKLOG-OWNER-TRUTH-SYNC.1` | `mdbook build docs/book`; `git diff --check` | `selection docs passed; no behavior changed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-BACKLOG-OWNER-TRUTH-SYNC.1` | `this commit: ISF-BACKLOG-OWNER-TRUTH-SYNC.1: select backlog owner truth sync` | `selects the book-facing backlog owner wording sync` |
| `ISF-BACKLOG-OWNER-TRUTH-SYNC.2` | `pending` | `pending` |

## Changelog

- `2026-05-22`: Created task tree and selected the book-facing backlog owner
  truth-sync frontier.
