# Task-Tree Tracking Setup Guide

This guide explains how to add the repo-local task-tree tracking workflow to a
new project.

Use this document when a project already has, or wants to add, a roadmap but
also needs a precise way to track task decomposition over time without losing
subtasks, blockers, decisions, or completion evidence.

## What The Task Tree Is For

The roadmap answers:

- What broad lanes exist?
- Which lane is active?
- What is done, in progress, left, or deferred at the workstream level?

The task tree answers:

- Which exact top-level task is being decomposed?
- Which subtasks and sub-subtasks exist?
- Which leaf is eligible to be picked next?
- What decisions, blockers, and open questions belong to this task?
- What validation and commit evidence closed each executable leaf?

The task tree is therefore a companion to roadmap intent. Its node list and
cross-tree index are the live work-status sources; it does not require a second
hand-maintained roadmap-status narrative.

## Files To Add

Minimum required files:

```text
docs/TASK_TREE.md
docs/tasks/TEMPLATE.md
docs/tasks/<FIRST-TREE>.md
docs/tasks/segments/<TREE>/manifest.jsonl  # optional for long-running trees
docs/tasks/segments/<TREE>/<SHA256>.md     # optional sealed subtree
doctrine/task_tree/index_archives.jsonl    # optional bounded completed-index history
```

Recommended project integration files:

```text
README.md
ROADMAP.md
COMMIT.md
SESSION_BOOTSTRAP.md
MEMORY.md
MEMORY_ARCHITECTURE.md
docs/decisions/INDEX.md
docs/book/
```

The exact live-doc names can differ in another project. What matters is that
the project has:

- one front-door navigation file,
- one high-level roadmap-intent file,
- one commit-workflow file,
- one session-start/bootstrap file,
- one bounded resume pointer,
- one durable decision store,
- one user-facing documentation surface,
- and git as the chronological history.

## File Roles

| File | Role |
| --- | --- |
| `docs/TASK_TREE_README.md` | Setup guide for installing this workflow in another project. |
| `docs/TASK_TREE.md` | Local operating spec, active task-tree index, and PNT selection rules. |
| `docs/tasks/TEMPLATE.md` | Copyable skeleton for each new top-level task tree. |
| `docs/tasks/<TREE>.md` | One task tree for one top-level task. |
| roadmap-intent file | High-level direction; links task trees when useful without mirroring their live frontier. |
| `COMMIT.md` | Commit workflow; requires task-file updates and leaf-ID traceability. |
| `README.md` | Project entry point; links the task-tree docs. |
| `SESSION_BOOTSTRAP.md` | Session startup ritual; tells agents to read active task trees. |
| `MEMORY.md` | Bounded overwrite-only recovery pointer to the latest commit, active leaf, and next action. |
| `docs/decisions/` | Durable accepted rationale and cross-cutting decisions. |
| mdBook or equivalent | User-facing behavior, examples, and supported-boundary documentation. |
| git | Chronological audit trail for completed work. |

## Minimum Setup

Use this when you want the workflow running with the fewest moving parts.

1. Create `docs/tasks/`.
2. Copy `docs/TASK_TREE.md` into the project.
3. Copy `docs/tasks/TEMPLATE.md` into the project.
4. Create the first task file from the template:

```text
docs/tasks/<FIRST-TREE>.md
```

5. Add the first task file to the `Active Task Trees` table in
   `docs/TASK_TREE.md`.
6. Add `docs/TASK_TREE.md` and `docs/tasks/TEMPLATE.md` to the project
   `README.md` or equivalent navigation file.
7. Add one rule to the commit workflow:

```text
If a completed activity belongs to a task-tree leaf, update the owning
docs/tasks/*.md file and identify the leaf ID in the commit subject or first
body line.
```

8. If useful, add one link from the high-level roadmap to the active tree:

```text
Task tree: docs/tasks/<FIRST-TREE>.md.
```

At that point the workflow is usable.

For repositories that adopt FSMGEN's mechanical enforcement layer, copy
`scripts/check_task_tree_integrity.pl`, add it to the local doctrine/CI driver,
and add focused fixture tests. The checker derives active task paths from the
`Active Task Trees` table and validates the authoritative live `## Task Tree`
node list plus any optional manifest-addressed sealed segments or exact
version-object terminals; it intentionally ignores optional historical views.

## Recommended Full Setup

Use this for a project where agents need reliable crash recovery, handoff
continuity, and PNT-style execution.

1. Add `docs/TASK_TREE_README.md`.
2. Add `docs/TASK_TREE.md`.
3. Add `docs/tasks/TEMPLATE.md`.
4. Create `docs/tasks/<FIRST-TREE>.md` from the template.
5. Add the first tree to the `Active Task Trees` table in `docs/TASK_TREE.md`.
6. Update `README.md`:
   - Add `docs/TASK_TREE_README.md` to the documentation index.
   - Add `docs/TASK_TREE.md` to the fast ramp-up order.
   - Add `docs/tasks/TEMPLATE.md` to the documentation index.
   - Add any active task files to the documentation index if the project keeps
     a full Markdown index.
7. Update `SESSION_BOOTSTRAP.md` or equivalent:
   - Read `README.md`.
   - Read `COMMIT.md`.
   - Read the bounded `MEMORY.md` resume pointer.
   - Read `docs/TASK_TREE.md`.
   - Read active task files listed in `docs/TASK_TREE.md`.
   - Pick work from the current frontier when the user asks for PNT.
8. Update the roadmap-intent file only when high-level intent changes:
   - Link the owning task tree when useful.
   - Do not mirror node status, the current frontier, or git history.
9. Update `COMMIT.md`:
   - Require task-tree files to be updated when node status, frontier,
     blockers, decisions, validation, or completion evidence changes.
   - Require the commit subject or first body line to include the leaf ID for
     task-tree-managed work.
   - Require one commit per completed leaf before selecting another leaf.
10. Route continuity and history through explicit layers:
    - `MEMORY.md`: overwrite the bounded latest-commit/active-leaf/next-action
      pointer.
    - `docs/decisions/`: record accepted durable rationale when warranted.
    - mdBook or equivalent: synchronize user-facing behavior and examples.
    - git: retain the chronological implementation and completion history.
11. Commit the setup as one documentation/workflow slice.

12. When mechanical doctrine enforcement is available, run
    `scripts/check_task_tree_integrity.pl` in the local hook/CI path so active
    root, node, ancestry, child-reference, status, container, and leaf-field
    drift fails closed.

## Adapting `docs/TASK_TREE.md`

Keep these sections:

- Purpose
- Active Task Trees
- Directory Layout
- Definitions
- ID Rules
- Status Vocabulary
- Required Task File Sections
- Node Rules
- Current Frontier Rules
- PNT Selection Rules
- Splitting Rules
- Completion Rules
- Blocker Rules
- Relationship To Live Docs

Customize these parts:

- Project name.
- Roadmap lane names.
- Live-doc filenames if the project uses different names.
- Commit-message policy if the project does not use `git_message_brief.txt`.
- Any project-specific default rule, such as "all ISF work is task-tree-managed"
  in FSMGen.

Remove project-specific sections that do not apply to the new project.

## Creating The First Task Tree

Create one file per top-level task. The file name should be stable and
descriptive:

```text
docs/tasks/API-STABILIZATION.md
docs/tasks/PARSER-DIAGNOSTICS.md
docs/tasks/UI-REDESIGN.md
docs/tasks/BUILD-CACHE.md
```

Choose a stable tree ID:

```text
API-STABILIZATION
PARSER-DIAGNOSTICS
UI-REDESIGN
BUILD-CACHE
```

Then define the first leaf:

```text
- ID: `API-STABILIZATION.1`
  Status: `pending`
  Goal: `Inventory current public API surfaces and name ownership boundaries.`
  Acceptance: `The task file lists public surfaces, owners, unknowns, and the next executable leaf.`
  Verification: `pending`
  Commit: `pending`
```

Add that leaf to the current frontier:

```text
| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `API-STABILIZATION.1` | `pending` | Policy and implementation need an accurate surface inventory first. |
```

## Operating Rules

Use these rules once the workflow is installed:

- PNT selects the first eligible leaf from the active tree's current frontier.
- Implement only one leaf at a time.
- Do not implement container nodes.
- If a leaf is too large, split it into child leaves before implementation.
- Keep node IDs stable forever.
- Do not renumber closed nodes.
- Record blockers with unblock conditions.
- Record decisions where they are made.
- Record validation in the owning task file.
- Update the bounded resume pointer and user-facing docs only where state or
  behavior changes; never duplicate the whole task tree or git history.
- Commit every completed leaf before selecting another leaf.

## Completion Evidence

A completed leaf should leave these traces:

- The task node status is `done`.
- The verification log names the checks run.
- The commit log names the commit subject or reference.
- The commit subject or first body line contains the leaf ID.
- The bounded resume pointer names the latest commit, active leaf, and next
  action.
- Durable decisions and user-facing docs are synchronized when warranted.

## Containing A Long-Running Tree

Keep ordinary trees in one file. When the authoritative task file itself
approaches its locally reviewed pressure budget, preserve a bounded live root
rather than splitting by arbitrary line count:

1. Keep task metadata, the top-level root, every nonterminal node, and every
   ancestor needed to reach the live frontier in `docs/tasks/<TREE>.md`.
2. Copy one or more fully terminal subtrees into a Markdown file with a
   `## Task Tree Segment` node list. Do not edit node bodies during the move.
3. Name the segment file by its SHA-256 and record it in the task's bounded
   JSONL manifest with disjoint root IDs, node count, digest, and the exact
   source revision/path.
4. Add this optional metadata line to the live task file:

```text
- Segment manifest: `docs/tasks/segments/<TREE>/manifest.jsonl`
```

5. Run the integrity checker before removing those nodes from the live file.
   It reconstructs one graph across files and rejects identity, ancestry,
   direct-child, status, provenance, or evidence drift.

The manifest starts with finite limits for its own records/bytes and for each
segment plus aggregate nodes/lines/bytes, followed by one record per content-
addressed segment:

```json
{"record_type":"registry","schema_version":1,"tree_id":"API-STABILIZATION","max_records":64,"max_bytes":65536,"max_segment_nodes":1024,"max_segment_lines":8192,"max_segment_bytes":524288,"max_total_nodes":4096,"max_total_lines":32768,"max_total_bytes":2097152}
{"record_type":"segment","schema_version":1,"segment_id":"API-STABILIZATION.1","path":"docs/tasks/segments/API-STABILIZATION/<SHA256>.md","root_ids":["API-STABILIZATION.1"],"node_count":12,"sha256":"<SHA256>","source_revision":"<FULL-REVISION>","source_path":"docs/tasks/API-STABILIZATION.md"}
```

When a completed subtree no longer warrants a working-tree segment, its root
may become one compact `version_object` terminal in the live node list. Record
the original goal, exact revision and path, retrieved-file SHA-256, archived
node count, closed verification, and commit reference. The checker reloads the
version object through git and validates the complete terminal subtree; a
conversation note, abbreviated revision, or unverified archive pointer is not
a substitute.

This optional topology refines the node-list authority rule without changing
PNT: current work is always selected from the live file, and the historical
frontier/log/changelog tables remain non-authoritative. Do not migrate a
healthy tree merely because the format exists.

The cross-tree index follows the same rule. Keep only active rows in its live
PNT table and proposed rows in its backlog table. When accumulated terminal
rows make the index a history ledger, seal the exact prior index version in a
finite JSONL manifest recording revision/path, SHA-256, dimensions, terminal
row count, unique tree-ID count, allowed terminal statuses, current pointer,
and sealing date. The integrity checker must retrieve that version, verify each
task-file link at the same revision, and reject terminal rows that leak back
into the live active/proposed views. The individual task files may remain
directly browsable; sealing duplicated index narration does not delete them.

Commit hashes do not have to be written into the same task-file update. The
hash is only known after commit. The reliable join key is the leaf ID in the
task file and commit message. Hashes can be backfilled later if the project
wants that extra index.

## What Not To Do

- Do not use the roadmap as the detailed task ledger.
- Do not put broad container tasks in the current frontier.
- Do not create vague children that cannot be verified.
- Do not duplicate the task tree or git history into a roadmap/status blob.
- Do not leave completed leaves uncommitted.
- Do not silently continue when a discovered subtask changes the scope; split
  the node and update the frontier.
- Do not renumber nodes after they have been referenced by commits or live
  docs.

## Setup Checklist

Use this checklist when enabling the workflow in a new project.

```text
[ ] docs/TASK_TREE_README.md exists.
[ ] docs/TASK_TREE.md exists and is customized for the project.
[ ] docs/tasks/TEMPLATE.md exists.
[ ] docs/tasks/<FIRST-TREE>.md exists.
[ ] docs/TASK_TREE.md lists the first active tree.
[ ] README.md links docs/TASK_TREE_README.md and docs/TASK_TREE.md.
[ ] The high-level roadmap links task trees where useful without mirroring live status.
[ ] COMMIT.md requires task-file updates and leaf-ID commit traceability.
[ ] SESSION_BOOTSTRAP.md reads docs/TASK_TREE.md and active task files.
[ ] MEMORY.md is bounded and points to the active leaf and next action.
[ ] Durable decisions, user-facing docs, and git each have explicit roles.
[ ] The setup is committed as one documentation/workflow slice.
[ ] If sealed segments are used, the manifest has finite bounds and exact source/retrieval fixtures pass.
[ ] If terminal index rows are query-first, their bounded exact-version manifest and PNT-view checks pass.
```

## Minimal First Commit Message

```text
Docs: add task-tree tracking workflow

- Add task-tree setup guide, local workflow, and reusable task template
- Create the first active task tree and current-frontier leaf
- Wire roadmap, commit workflow, and startup docs to the task-tree ledger
```
