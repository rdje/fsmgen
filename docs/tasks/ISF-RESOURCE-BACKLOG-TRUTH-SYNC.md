# ISF-RESOURCE-BACKLOG-TRUTH-SYNC: Resource Backlog Truth Synchronization

## Metadata

- Tree ID: `ISF-RESOURCE-BACKLOG-TRUTH-SYNC`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Synchronize the canonical mdBook feature backlog with the already-shipped
resource-arbitration boundary and the still-deferred per-cycle resource
grant/debug storage surface.

## Non-Goals

- Do not change parser, scheduler, report payload, generated `.fsm`, or HDL
  behavior.
- Do not implement new resource kinds, arbiters, runtime grant traces, or
  debug storage.
- Do not freeze the whole schedule JSON schema.

## Acceptance Criteria

- The scalar-authoring backlog status no longer mentions resource kinds.
- The enforced-resource-arbitration backlog status says the shipped
  `rule_slot`/`priority` subset is partially shipped and broader resource
  kinds/arbiters remain backlog.
- The richer storage-class backlog explicitly defers per-cycle
  resource-grant/debug storage unless future lowering materializes such
  signals.
- mdBook and diff hygiene validation pass.
- Live docs, task tree, changes, and development notes are synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-RESOURCE-BACKLOG-TRUTH-SYNC`
  Status: `done`
  Goal: `Synchronize resource-related backlog truth in the canonical book.`
  Children: `ISF-RESOURCE-BACKLOG-TRUTH-SYNC.1`

- ID: `ISF-RESOURCE-BACKLOG-TRUTH-SYNC.1`
  Status: `done`
  Goal: `Correct resource arbitration and storage-role backlog wording.`
  Acceptance: `The canonical mdBook backlog accurately distinguishes shipped resource arbitration from deferred resource-grant/debug storage.`
  Verification: `mdBook build and diff hygiene passed.`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-RESOURCE-BACKLOG-TRUTH-SYNC.1` | `done` | Completed; tree closed. |

## Decisions

- `2026-05-16`: Treat this as documentation-truth synchronization only. The
  shipped behavior already lives in resource arbitration lowering and
  `resource_arbitration[]`; per-cycle resource grant/debug storage is still a
  future feature.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-RESOURCE-BACKLOG-TRUTH-SYNC.1` | `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-RESOURCE-BACKLOG-TRUTH-SYNC.1` | `ISF-RESOURCE-BACKLOG-TRUTH-SYNC.1: sync resource backlog truth` | `pending commit` |

## Changelog

- `2026-05-16`: Created task tree and opened the first truth-sync leaf.
- `2026-05-16`: Completed the first leaf and closed the tree.
