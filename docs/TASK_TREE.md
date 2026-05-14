# Repo-Local Task Tree Workflow

This document defines the repo-local task-tree workflow used by FSMGen.
It is intentionally portable: another project can copy this file, the
`docs/tasks/TEMPLATE.md` template, and the commit-subject rule, then replace
the roadmap lane names and live-doc file names with local equivalents.

For a step-by-step setup guide that can be reused by another project, read
[docs/TASK_TREE_README.md](docs/TASK_TREE_README.md).

## Purpose

Use a task tree when a top-level task is too broad to finish safely as one
signoff-level slice, or when a task is expected to discover subtasks and
sub-subtasks over time.

The goal is not to create a second roadmap. The roadmap states the high-level
workstream direction. A task tree owns the recursive breakdown, current
frontier, acceptance criteria, blockers, decisions, validation, and completion
evidence for one top-level task.

## Active Task Trees

| Tree | Status | Roadmap lane | Current frontier | File |
| --- | --- | --- | --- | --- |
| `ISF-CONFLICTS` | `active` | `R14` | `ISF-CONFLICTS.5.4` | [docs/tasks/ISF-CONFLICT-RESOLUTION.md](docs/tasks/ISF-CONFLICT-RESOLUTION.md) |
| `ISF-COMPOSITION` | `active` | `R14` | `ISF-COMPOSITION.1` | [docs/tasks/ISF-COMPOSITION-INSTANTIATION.md](docs/tasks/ISF-COMPOSITION-INSTANTIATION.md) |
| `ISF-RESOURCE-PRIORITY` | `active` | `R14` | `ISF-RESOURCE-PRIORITY.1` | [docs/tasks/ISF-RESOURCE-PRIORITY.md](docs/tasks/ISF-RESOURCE-PRIORITY.md) |
| `ISF-RULE-ACTIONS` | `active` | `R14` | `ISF-RULE-ACTIONS.1` | [docs/tasks/ISF-RULE-ACTIONS.md](docs/tasks/ISF-RULE-ACTIONS.md) |
| `ISF-STAGES-CONTRACTS` | `active` | `R14` | `ISF-STAGES-CONTRACTS.1` | [docs/tasks/ISF-STAGES-CONTRACTS.md](docs/tasks/ISF-STAGES-CONTRACTS.md) |
| `ISF-DATA-WIDTHS` | `active` | `R14` | `ISF-DATA-WIDTHS.1` | [docs/tasks/ISF-DATA-WIDTHS.md](docs/tasks/ISF-DATA-WIDTHS.md) |
| `ISF-SCHEDULE-REPORTS` | `active` | `R14` | `ISF-SCHEDULE-REPORTS.1` | [docs/tasks/ISF-SCHEDULE-REPORTS.md](docs/tasks/ISF-SCHEDULE-REPORTS.md) |
| `ISF-FIXTURES` | `active` | `R14` | `ISF-FIXTURES.1` | [docs/tasks/ISF-FIXTURE-COVERAGE.md](docs/tasks/ISF-FIXTURE-COVERAGE.md) |
| `ISF-COMPATIBILITY` | `active` | `R14` | `ISF-COMPATIBILITY.1` | [docs/tasks/ISF-COMPATIBILITY-SURFACE.md](docs/tasks/ISF-COMPATIBILITY-SURFACE.md) |
| `ISF-PUBLIC-CONTRACT` | `active` | `R14` | `ISF-PUBLIC-CONTRACT.1` | [docs/tasks/ISF-PUBLIC-CONTRACT-SYNC.md](docs/tasks/ISF-PUBLIC-CONTRACT-SYNC.md) |

## R14 ISF Objective Coverage

All currently documented ongoing or unresolved R14 ISF objective families have
task-tree ownership. Already-shipped base objectives such as parsing `.isf`
actors, lowering through `LoweringIR`, emitting scheduled `.fsm`, schedule JSON
emission, and HDL handoff remain recorded in [ROADMAP_STATUS.md](ROADMAP_STATUS.md)
as done work unless a future task reopens them.

| ISF objective family | Owning tree |
| --- | --- |
| Same-cycle output conflicts, fan-in, and fail-closed drive policy | `ISF-CONFLICTS` |
| Generated-child top instantiation and spawn parameter binding | `ISF-COMPOSITION` |
| Resource arbitration and priority enforcement | `ISF-RESOURCE-PRIORITY` |
| Expression-valued rule assignments and rule action widening | `ISF-RULE-ACTIONS` |
| Transaction stage lowering and temporal contract lowering | `ISF-STAGES-CONTRACTS` |
| Data-operation width inference for shift/extract/assemble families | `ISF-DATA-WIDTHS` |
| Schedule-report storage classes and schedule JSON stabilization | `ISF-SCHEDULE-REPORTS` |
| Realistic protocol fixtures, strict-mode checks, and end-to-end coverage | `ISF-FIXTURES` |
| Legacy handshake metadata and removed transaction `assign` compatibility | `ISF-COMPATIBILITY` |
| ISF spec, mdBook, public interface contract, and manifest synchronization | `ISF-PUBLIC-CONTRACT` |

## ISF Task-Tree Rule

All ISF work under `R14` is task-tree-managed by default.

Before implementing any ISF task, slice, or PNT-selected activity:

- Attach it to an existing active ISF task tree, or create a new
  `docs/tasks/*.md` tree from [docs/tasks/TEMPLATE.md](docs/tasks/TEMPLATE.md).
- Slice the work into executable leaf nodes before changing scheduler,
  parser, emitter, contract, fixture, or book content.
- Put only executable leaf nodes in the tree's current frontier.
- Implement one frontier leaf at a time.
- Update the owning task file when the leaf status, blocker, decision,
  validation evidence, or completion evidence changes.
- Run the full [COMMIT.md](COMMIT.md) workflow after each completed leaf before
  selecting another ISF leaf.

Small ISF documentation-only or diagnostics-only changes still need a tree
entry. If the change is genuinely small, the tree can contain one leaf, but the
task must still be visible in the task-tree ledger before implementation.

## Directory Layout

```text
docs/TASK_TREE.md
docs/tasks/
  TEMPLATE.md
  <TREE>.md
```

`docs/TASK_TREE.md` is the workflow and active-tree index.
Each top-level task owns one file in `docs/tasks/`.
`docs/tasks/TEMPLATE.md` is copied when creating a new top-level tree.

## Definitions

- Task tree: the recursive decomposition of one top-level task.
- Node: one item in that tree.
- Container node: a node with children. It is not directly executable.
- Leaf node: a node with no children. It is the only unit PNT may implement.
- Current frontier: the ordered set of leaf nodes that are eligible to be
  picked next.
- Slice: one completed leaf task plus its tests, docs, live-doc updates, and
  commit workflow.
- Evidence: the validation output, changed-doc summary, and git commit subject
  that prove a leaf was completed.

## ID Rules

Each task tree has a stable top-level ID.

```text
<TREE>
<TREE>.1
<TREE>.1.1
<TREE>.1.1.1
```

Rules:

- `<TREE>` uses uppercase letters, digits, and hyphens.
- Child IDs append dot-separated positive integers.
- IDs are permanent once published.
- Never renumber closed nodes.
- If a new ordering is needed, add new IDs and mark old nodes `superseded` or
  `deferred` with a reason.
- A commit that completes a task-tree leaf must identify the leaf ID in the
  commit subject or in the first body line.

## Status Vocabulary

Use only these statuses.

| Status | Meaning |
| --- | --- |
| `proposed` | Captured but not yet accepted into the active tree. |
| `active` | The top-level tree is open, or a container has unfinished children. |
| `pending` | Ready to be selected once it reaches the current frontier. |
| `in_progress` | Currently being implemented in the worktree. |
| `blocked` | Cannot proceed without a named blocker and unblock condition. |
| `done` | Completed, validated, documented, and committed. |
| `deferred` | Deliberately postponed with an explicit consequence. |
| `superseded` | Replaced by another node, with the replacement ID named. |

## Required Task File Sections

Every top-level task file must contain:

- Metadata: tree ID, status, roadmap lane, created date, last updated date.
- Goal: the user-visible or project-visible outcome.
- Non-goals: what this tree deliberately does not try to solve.
- Acceptance criteria: concrete conditions that close the top-level task.
- Task tree: all known nodes, with status and short result intent.
- Current frontier: ordered leaf nodes that PNT may select next.
- Decisions: accepted technical decisions and their rationale.
- Open questions: unresolved questions that do not block the whole tree yet.
- Blockers: blockers with unblock conditions.
- Verification log: checks run for completed leaves.
- Commit log: leaf IDs mapped to completion commit subjects.
- Changelog: dated edits to the tree itself.

## Node Rules

Every node must be one of these two shapes.

Container node:

```text
- ID: <TREE>.<n>
  Status: active
  Goal: ...
  Children: <TREE>.<n>.1, <TREE>.<n>.2
```

Leaf node:

```text
- ID: <TREE>.<n>
  Status: pending
  Goal: ...
  Acceptance: ...
  Verification: pending
  Commit: pending
```

A node with children must not be marked `done` until every child is `done`,
`deferred`, or `superseded`, and every non-`done` child has a recorded reason.

## Current Frontier Rules

The current frontier is the only list PNT uses when selecting work from a task
tree.

Rules:

- The frontier contains only leaf nodes.
- The frontier is ordered by intended priority.
- A container never appears in the frontier.
- A blocked node stays out of the frontier until unblocked.
- When a leaf is split, remove that leaf from the frontier, mark it `active`,
  add children, and place the first executable child or children in the
  frontier.
- When a leaf completes, remove it from the frontier and add the next eligible
  leaf or leaves.

## PNT Selection Rules

When PNT is asked to continue and at least one active task tree exists:

1. Read `docs/TASK_TREE.md`.
2. Read the active task file named in the `Active Task Trees` table.
3. Pick the first eligible leaf in that file's `Current Frontier`.
4. Implement only that leaf.
5. If the leaf is too broad, split it before implementation and commit the
   tree update as the leaf's honest outcome.
6. Run the required validation for the leaf.
7. Update the task file, live docs, and roadmap if status changed.
8. Run the full commit workflow before selecting another leaf.

If several active trees exist, choose the first active tree in the table unless
the user names another tree or the roadmap status names a different immediate
lane.

## Splitting Rules

Split a node when any of these are true:

- It cannot be completed to signoff quality in one slice.
- It mixes design, implementation, diagnostics, tests, and docs in ways that
  can be reviewed independently.
- It hides an unresolved policy choice behind implementation wording.
- It would require touching unrelated ownership areas in one commit.
- It discovers a lower-level dependency that should be solved first.

Do not split merely to create vague placeholders. Every child must have a
clear goal and a way to verify completion.

## Completion Rules

A leaf is complete only when all of the following are true:

- Implementation or documentation work for that leaf is finished.
- Focused checks passed, and broader checks ran when warranted.
- The owning task file records the result, validation, and commit subject.
- `MEMORY.md`, `CHANGES.md`, `DEVELOPMENT_NOTES.md`,
  `LIVE_ACHIEVEMENT_STATUS.md`, and `ROADMAP_STATUS.md` are updated when the
  leaf changes project state.
- The commit workflow in `COMMIT.md` has completed.
- `git_message_brief.txt` has been cleared after commit.

Commit hashes are intentionally not required inside the same task-file update:
the final hash cannot be known until after the commit exists. The stable
join key is the leaf ID in the commit subject or first body line. Later status
refreshes may backfill hashes if useful.

## Blocker Rules

A blocked node must record:

- the exact blocker,
- why it blocks the node,
- the unblock condition,
- and the next task that should run instead, if any.

Do not leave a node as `blocked` only because it is large or unclear. Large or
unclear work should be split until a real blocker is visible.

## Relationship To Live Docs

The task tree is the detailed execution ledger.

- `ROADMAP_STATUS.md` remains the canonical high-level workstream status.
- `MEMORY.md` remains the recovery/handoff continuity log.
- `CHANGES.md` remains the chronological technical history.
- `DEVELOPMENT_NOTES.md` remains design rationale.
- `LIVE_ACHIEVEMENT_STATUS.md` remains the latest completed slice summary.
- The mdBook remains user-facing product/language documentation.

Do not duplicate the whole task tree into those files. Link to the task tree
and summarize only the part that changes live project state.

## Copying This Workflow To Another Project

The detailed project-adoption checklist lives in
[docs/TASK_TREE_README.md](docs/TASK_TREE_README.md).

To reuse this approach elsewhere:

1. Copy `docs/TASK_TREE_README.md`.
2. Copy `docs/TASK_TREE.md`.
3. Copy `docs/tasks/TEMPLATE.md`.
4. Add `docs/tasks/` to the project documentation index.
5. Add a commit-workflow rule requiring completed task-tree leaf commits to
   identify the leaf ID.
6. Add the task-tree file to the session bootstrap or fast ramp-up order.
7. Create one top-level task file per broad task.
8. Keep the roadmap high-level and the task files detailed.

The only project-specific parts are roadmap lane names, live-doc filenames,
validation commands, and commit-message conventions.
