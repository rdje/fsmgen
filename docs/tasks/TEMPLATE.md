# <TREE-ID>: <Task Title>

## Metadata

- Tree ID: `<TREE-ID>`
- Status: `proposed`
- Roadmap lane: `<Rj or local lane>`
- Created: `YYYY-MM-DD`
- Last updated: `YYYY-MM-DD`
- Owner: repo-local workflow

## Goal

State the exact outcome this top-level task must deliver.

## Non-Goals

- State what this task deliberately does not solve.

## Acceptance Criteria

- The behavior, documentation, or infrastructure outcome is implemented.
- Focused validation passes.
- Broader validation runs when the blast radius warrants it.
- `scripts/check_task_tree_integrity.pl` passes while this tree is active.
- The task index and bounded resume pointer are updated where project state
  changed; durable decisions and user-facing docs are synchronized when
  warranted.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `<TREE-ID>`
  Status: `active`
  Goal: `<top-level goal>`
  Children: `<TREE-ID>.1`

- ID: `<TREE-ID>.1`
  Status: `pending`
  Goal: `<first executable leaf>`
  Acceptance: `<what proves this leaf is done>`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

<!-- Optional historical snapshot (decision 0019). The live frontier is the
     eligible (active/pending, unblocked) leaves in the ## Task Tree node list
     above; this table is not required to be maintained per-slice and may be
     omitted. -->

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `<TREE-ID>.1` | `pending` | `<reason>` |

## Decisions

- `YYYY-MM-DD`: `<decision and rationale>`

## Open Questions

- `<question, owner, and why it does or does not block the frontier>`

## Blockers

- None.

## Acceptance Checklist (enforced for implementation changes)

<!-- Required and freshly checked in the staged slice whenever a path declared
     by doctrine/task_acceptance/change_paths.tsv changes. See
     TASK_ACCEPTANCE.md and TOOLBOX.md. Documentation-only slices are exempt. -->

- [ ] **ROOT CAUSE (WHY + WHERE)** — `<tool output naming the mechanism and locus>`
- [ ] **ADDRESSED (verified)** — `<before→after result from a named command>`
- [ ] **NO REGRESSION** — `<named broader gate and deterministic result>`

## Verification Log

<!-- Optional historical snapshot (decision 0019). Each leaf's Verification field
     in the ## Task Tree node list is the live record; this section is not
     required to be maintained per-slice and may be omitted. -->

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `YYYY-MM-DD` | `<TREE-ID>.1` | `pending` | `pending` |

## Commit Log

<!-- Optional historical snapshot (decision 0019). Each leaf's Commit field in
     the node list and `git log --grep=<TREE-ID>` are the live record; this
     section is not required to be maintained per-slice and may be omitted. -->

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `<TREE-ID>.1` | `pending` | `pending` |

## Changelog

<!-- Optional historical snapshot (decision 0019). Git is the audit trail; this
     section is not required to be maintained per-slice and may be omitted. -->

- `YYYY-MM-DD`: Created task tree.
