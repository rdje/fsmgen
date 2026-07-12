# 0019 — Task-tree in-file secondary views are historical, not per-slice-maintained

- Date: `2026-07-12`
- Status: accepted
- Type: convention
- Owner tree: `TASK-TREE-AUX-VIEW-DRIFT-RESOLUTION`

## Context

Every per-task-tree file (`docs/tasks/*.md`) carries four in-file secondary
views in addition to the authoritative **`## Task Tree` node list**: a
`## Current Frontier` table, a `## Verification Log`, a `## Commit Log`, and a
`## Changelog`.

In the large, long-running `IAL2-FEATURE-COMPLETENESS-FRONTIER.md` tree these
four views had silently lagged the node list by 6–10 slices (the node list and
`docs/TASK_TREE.md` were current through `.782`, while `## Current Frontier`
still showed `.773` marked `active`, `## Commit Log` stopped at `.776`,
`## Verification Log` at `.773`, and `## Changelog` at `.772`). Recent slices had
updated the node list, `docs/TASK_TREE.md`, `MEMORY.md`, and the user-facing docs
but not these four views, so an implicit "the node list is the source of truth;
those tables are legacy" convention had taken hold without being written down —
leaving stale, misleading data in a tracked file.

The four views carry no information that is not already in the node list (each
leaf's `Status`, `Goal`, `Verification`, and `Commit` fields) or in git. A
`## Commit Log` and a `## Changelog` that re-narrate commits are the same
anti-pattern that decision `0007` froze for the root prose blobs
(`CHANGES.md`/`DEVELOPMENT_NOTES.md`): re-narrating git history into prose that
goes stale.

## Decision

The **authoritative, live sources** for a task tree's frontier, verification, and
history are:

- the `## Task Tree` **node list** (layer B) — each leaf's `Status` is the live
  state; the eligible (`active`/`pending`, unblocked) leaves are the frontier;
  each leaf's `Verification` and `Commit` fields hold its verification and
  completion commit;
- `docs/TASK_TREE.md` (the cross-tree live index); and
- `git log --grep=<TREE-ID>` (layer D) — the audit trail.

The four in-file secondary views — `## Current Frontier`, `## Verification Log`,
`## Commit Log`, and `## Changelog` — are **optional historical convenience
snapshots**. They are **not required to be maintained per-slice**, and a slice is
complete without updating them. Existing stale views are **stamped as historical
(pointing at the live sources), not backfilled**. Chosen over a
regenerate-and-check "keep them in sync" approach because the views duplicate the
node list + git and carry nothing unique; removing the maintenance obligation
makes drift structurally impossible rather than merely detected, and avoids a
generator + doctrine check that would exist only to keep duplicating information.

PNT selection reads the node list's eligible leaves (not the `## Current
Frontier` table). This matches actual practice: PNT continued correctly through
`.774`–`.782` from the node list + `MEMORY.md` while the `## Current Frontier`
table was stale.

## Consequences

- `docs/TASK_TREE.md` "Required Task File Sections", "Current Frontier Rules", and
  "PNT Selection Rules" are updated: the node list's eligible leaves are the
  frontier and the PNT selection source; the four in-file views are optional and
  historical.
- `docs/tasks/TEMPLATE.md` marks the four sections optional/historical.
- `IAL2-FEATURE-COMPLETENESS-FRONTIER.md`'s four views are stamped historical with
  a pointer to the live sources; they are not backfilled.
- Completed task-tree files are **not** swept — their views are accurate,
  finished snapshots, not misleading drift; they are historical by construction.
- No generator and no new doctrine check are added; there is nothing to keep in
  sync, so nothing to drift. Consistent with `0007` (git is the audit trail) and
  `MEMORY_ARCHITECTURE.md` (prefer derived/authoritative over hand-duplicated).
