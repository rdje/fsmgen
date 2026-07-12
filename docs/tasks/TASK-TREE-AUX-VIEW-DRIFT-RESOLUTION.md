# TASK-TREE-AUX-VIEW-DRIFT-RESOLUTION: secondary status views in large task trees lag the authoritative node list

## Metadata

- Tree ID: `TASK-TREE-AUX-VIEW-DRIFT-RESOLUTION`
- Status: `proposed`
- Roadmap lane: `infra/continuity`
- Created: `2026-07-12`
- Last updated: `2026-07-12`
- Owner: repo-local workflow

## Goal

Decide, and then apply, a single durable convention for the **secondary status
views** inside long per-task-tree files (the `## Current Frontier` table, the
`## Verification Log` `###` subsections, the `## Commit Log` table, and the
`## Changelog`) so they either stay in sync with the authoritative node list or
are explicitly retired — instead of silently lagging it by many slices and
misleading a reader.

This tree is **proposed, not PNT-eligible**: it changes a continuity/doc
convention that spans every task-tree file, so it needs the director's judgment
on *backfill-and-maintain* versus *retire-in-favor-of-the-node-list* before any
sweep.

## Background / Finding

Surfaced on 2026-07-12 while navigating
`docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md` during
`IAL2-FEATURE-COMPLETENESS-FRONTIER.779`–`.781`.

That file's authoritative **node list** (`- ID:` entries) and its **Children
continuation** list are current through `.782`. But four secondary views have
lagged for 6–10 slices:

```text
## Current Frontier   last data row: .773 (marked `active`)  -- .782 is active; .773-.781 are done
## Commit Log         last row:      .776                    -- missing .777-.781
## Verification Log    last ### block: .773                   -- missing .774-.781
## Changelog          most recent:    .772                    -- missing .773-.781
```

The recent selector/implementation slices (`.774`–`.781`) each updated the node
list, the Children-continuation list, `docs/TASK_TREE.md`, `MEMORY.md`, and the
user-facing docs, but did **not** touch these four in-file secondary views. So an
implicit "the node list is the source of truth; these tables are legacy"
convention has taken hold without being written down, leaving stale-looking data
in a tracked file: a reader who consults `## Current Frontier` is told `.773` is
the active frontier when it is `.782`.

The same shape is likely present in other large, long-running task-tree files.

## Non-Goals

- Do not change any FSMGen product behavior; this is infra/continuity only.
- Do not delete the authoritative node list or the Children-continuation list.
- Do not silently backfill without first choosing the convention (a backfill and
  a retirement are opposite resolutions; picking one is the point of this tree).
- Do not change `COMMIT.md`/`MEMORY_ARCHITECTURE.md` layer definitions; at most
  clarify which in-file views are normative.

## Acceptance Criteria

- A recorded decision (director-approved) choosing one convention:
  - **(A) Maintain**: the per-slice workflow updates `## Current Frontier`,
    `## Commit Log`, `## Verification Log`, and `## Changelog` in the same slice
    as the node list — preferably via a generator so they cannot drift; or
  - **(B) Retire**: mark those four in-file views as frozen/deprecated (like the
    root legacy prose blobs in `docs/decisions/0007`), naming the node list +
    `docs/TASK_TREE.md` + git as the live sources, and either remove the stale
    tables or stamp them with a "historical, not maintained past `.NNN`" banner.
- Whichever is chosen, `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md` (and
  any other large tree with the same lag) is brought into compliance with it.
- If a maintain-convention is chosen, a lightweight check (or a note in
  `COMMIT.md` / the task-tree README) makes the expectation explicit so it does
  not re-drift.

## Task Tree

- ID: `TASK-TREE-AUX-VIEW-DRIFT-RESOLUTION`
  Status: `proposed`
  Goal: `Choose and apply one convention for task-tree secondary status views.`
  Children: `TASK-TREE-AUX-VIEW-DRIFT-RESOLUTION.1`

- ID: `TASK-TREE-AUX-VIEW-DRIFT-RESOLUTION.1`
  Status: `pending`
  Goal: `Select maintain-vs-retire for the four in-file secondary views and the enforcement/backfill plan before touching any task-tree file.`
  Acceptance: `Chosen convention (A maintain or B retire), the affected views (## Current Frontier, ## Commit Log, ## Verification Log, ## Changelog), the set of task-tree files that carry the lag, the backfill-or-freeze plan, whether a generator/check is added, and the COMMIT.md / TASK_TREE README wording, with the director's approval.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `TASK-TREE-AUX-VIEW-DRIFT-RESOLUTION.1` | `pending` | Needs a director decision on a cross-cutting continuity convention; proposed until then. |

## Decisions

- `2026-07-12`: Filed as `proposed` (not PNT-eligible). The resolution is a
  cross-cutting continuity convention (backfill vs. retire) affecting every
  task-tree file, so it needs the director's explicit direction before a sweep.

## Open Questions

- Should the four secondary views be regenerated from the node list by a script
  (so they cannot drift), or retired as historical?
- Are these views load-bearing for any current reader/tool, or is
  `docs/TASK_TREE.md` + the node list already the effective source of truth?

## Blockers

- Director decision on the maintain-vs-retire convention.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-07-12` | `finding` | Compared node list / Children-continuation vs. `## Current Frontier` / `## Commit Log` / `## Verification Log` / `## Changelog` in `IAL2-FEATURE-COMPLETENESS-FRONTIER.md` | `confirmed`: node list current through `.782`; the four secondary views last updated at `.773`/`.776`/`.773`/`.772` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `finding` | `TASK-TREE-AUX-VIEW-DRIFT-RESOLUTION` filing | Finding surfaced during `IAL2-FEATURE-COMPLETENESS-FRONTIER.779`–`.781` and this proposed owner filed. |

## Changelog

- `2026-07-12`: Created proposed task tree from the task-tree secondary-view
  drift observed in `IAL2-FEATURE-COMPLETENESS-FRONTIER.md`.
