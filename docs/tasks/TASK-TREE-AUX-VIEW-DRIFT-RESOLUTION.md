# TASK-TREE-AUX-VIEW-DRIFT-RESOLUTION: secondary status views in large task trees lag the authoritative node list

## Metadata

- Tree ID: `TASK-TREE-AUX-VIEW-DRIFT-RESOLUTION`
- Status: `done`
- Roadmap lane: `infra/continuity`
- Created: `2026-07-12`
- Last updated: `2026-07-12`
- Owner: repo-local workflow

> Resolution: director approved applying the fix on 2026-07-12; chose **(B)
> retire the in-file secondary views as historical**, recorded as decision
> [0019](../decisions/0019-task-tree-in-file-secondary-views-are-historical.md).

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
  Status: `done`
  Goal: `Choose and apply one convention for task-tree secondary status views.`
  Children: `TASK-TREE-AUX-VIEW-DRIFT-RESOLUTION.1`

- ID: `TASK-TREE-AUX-VIEW-DRIFT-RESOLUTION.1`
  Status: `done`
  Goal: `Select maintain-vs-retire for the four in-file secondary views and the enforcement/backfill plan before touching any task-tree file.`
  Acceptance: `Chosen convention (A maintain or B retire), the affected views (## Current Frontier, ## Commit Log, ## Verification Log, ## Changelog), the set of task-tree files that carry the lag, the backfill-or-freeze plan, whether a generator/check is added, and the COMMIT.md / TASK_TREE README wording, with the director's approval.`
  Verification: `Director approved applying the fix (2026-07-12). Chose (B) retire the four in-file secondary views as historical rather than (A) maintain-via-generator, because they duplicate the authoritative node list (each leaf's Status/Verification/Commit) plus git and carry nothing unique — the 0007 re-narration anti-pattern — so removing the maintenance obligation makes drift structurally impossible instead of merely detected, with no generator/doctrine-check to build. Recorded as decision docs/decisions/0019 (+ INDEX row). Updated the normative rules in docs/TASK_TREE.md: Required Task File Sections now marks the node list authoritative and the four views optional/historical; Current Frontier Rules and PNT Selection step 3 now select the earliest active/pending unblocked leaf from the node list (not the ## Current Frontier table). Marked the four sections optional/historical in docs/tasks/TEMPLATE.md. Stamped the four sections in docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md as historical with a live-source pointer (not backfilled). Completed task-tree files were deliberately NOT swept — their views are accurate finished snapshots, not misleading drift. Added a Knowledge Map fact card; regenerated KNOWLEDGE_MAP.md. Doctrine, Knowledge Map, doc-path, mdBook, and diff gates pass.`
  Commit: `TASK-TREE-AUX-VIEW-DRIFT-RESOLUTION.1: retire lagging in-file task-tree views (decision 0019)`

## Current Frontier

Complete — no eligible leaf remains (`.1` is `done`).

## Decisions

- `2026-07-12`: Filed as `proposed` (not PNT-eligible). The resolution is a
  cross-cutting continuity convention (backfill vs. retire) affecting every
  task-tree file, so it needs the director's explicit direction before a sweep.
- `2026-07-12`: Director approved applying the fix. Chose **(B) retire** the four
  in-file secondary views as historical (not (A) maintain-via-generator): they
  duplicate the node list + git and carry nothing unique (the `0007`
  re-narration anti-pattern), so retiring them makes drift structurally
  impossible with no generator/check to maintain. Recorded as decision `0019`.
  Applied to `docs/TASK_TREE.md` rules, `docs/tasks/TEMPLATE.md`, and the stale
  `IAL2-FEATURE-COMPLETENESS-FRONTIER.md` views (stamped, not backfilled).
  Completed task-tree files are not swept — their views are accurate finished
  snapshots, not misleading drift.

## Open Questions

- Should the four secondary views be regenerated from the node list by a script
  (so they cannot drift), or retired as historical?
- Are these views load-bearing for any current reader/tool, or is
  `docs/TASK_TREE.md` + the node list already the effective source of truth?

## Blockers

- None (resolved: director approved the maintain-vs-retire convention on
  2026-07-12; chose retire, decision `0019`).

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
