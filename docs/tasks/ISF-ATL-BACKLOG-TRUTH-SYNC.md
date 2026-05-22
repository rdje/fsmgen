# ISF-ATL-BACKLOG-TRUTH-SYNC: ATL Backlog Truth Synchronization

## Metadata

- Tree ID: `ISF-ATL-BACKLOG-TRUTH-SYNC`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Synchronize stale ATL backlog prose with the shipped ATL codebase and public
contract after compact group aliases, compact instance aliases, multi-event
waits, generated ATL tops, and generated-child route families shipped.

## Non-Goals

- Do not change parser, scheduler, lowerer, generated `.fsm`, HDL, or public
  API behavior.
- Do not select or implement new ATL source syntax.
- Do not reclassify deferred features as shipped without executable coverage.

## Acceptance Criteria

- The stale backlog claim that generated ATL tops are still excluded is
  corrected to reflect the bounded generated-top subsets that are shipped.
- The corrected prose remains explicit about deferred route mux/storage,
  handoff storage, inferred child interface bindings outside shipped subsets,
  compact movement aliases, and broader fail-closed boundaries.
- The mdBook remains synchronized with the ISF spec, downstream handoff,
  public contract, ATL design proposal, roadmap status, task tree, and live
  docs.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-ATL-BACKLOG-TRUTH-SYNC`
  Status: `active`
  Goal: `synchronize ATL backlog truth after recent ATL shipped subsets`
  Children: `ISF-ATL-BACKLOG-TRUTH-SYNC.1`,
  `ISF-ATL-BACKLOG-TRUTH-SYNC.2`

- ID: `ISF-ATL-BACKLOG-TRUTH-SYNC.1`
  Status: `done`
  Goal: `select the ATL backlog truth-sync task tree`
  Acceptance: `task-tree owner, stale statement, boundaries, and doc-sync leaf are recorded before edits`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `pending this commit`

- ID: `ISF-ATL-BACKLOG-TRUTH-SYNC.2`
  Status: `pending`
  Goal: `synchronize stale ATL backlog generated-top and deferred-feature prose`
  Acceptance: `book-facing ATL backlog prose matches shipped generated-top behavior and explicit deferrals`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-ATL-BACKLOG-TRUTH-SYNC.2` | `pending` | The mdBook backlog still says generated ATL tops are excluded even though bounded generated ATL tops are shipped. |

## Decisions

- `2026-05-22`: Treat this as a documentation truth-sync slice with no code or
  behavior changes.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| 2026-05-22 | `ISF-ATL-BACKLOG-TRUTH-SYNC.1` | `mdbook build docs/book`; `git diff --check` | Pass |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-ATL-BACKLOG-TRUTH-SYNC.1` | `pending this commit: ISF-ATL-BACKLOG-TRUTH-SYNC.1: select ATL backlog truth sync` | Selection commit. |

## Changelog

- `2026-05-22`: Created active R14 documentation truth-sync tree for stale ATL
  backlog prose.
