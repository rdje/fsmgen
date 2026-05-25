# TASK-TREE-COMMIT-EVIDENCE-TRUTH-SYNC: Task-Tree Commit Evidence Truth Sync

## Metadata

- Tree ID: `TASK-TREE-COMMIT-EVIDENCE-TRUTH-SYNC`
- Status: `active`
- Roadmap lane: `roadmap maintenance`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Replace stale `pending commit` and `pending this commit` evidence in completed
task-tree files with concrete completion subjects or commit references so the
task-tree corpus remains truthful for review and crash recovery.

## Non-Goals

- Do not change parser, scheduler, emitter, generated artifact, HDL, CLI,
  public API, or runtime behavior.
- Do not reopen completed task trees.
- Do not infer or rewrite acceptance criteria beyond commit-evidence truth.
- Do not edit `docs/tasks/TEMPLATE.md` placeholder examples or
  `docs/TASK_TREE.md` workflow examples.

## Acceptance Criteria

- The task tree is selected before commit-evidence repair edits begin.
- Completed task files with stale `pending commit`, `pending this commit`,
  `pending commit hash`, or `pending commit workflow` evidence are audited.
- Recoverable stale evidence is replaced by concrete completion subjects or
  commit references without changing the task outcome.
- Any remaining `pending` wording is either in templates/workflow examples,
  active unfinished leaves, or explicitly justified.
- Focused text audits, `mdbook build docs/book`, and `git diff --check` pass.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `TASK-TREE-COMMIT-EVIDENCE-TRUTH-SYNC`
  Status: `active`
  Goal: `synchronize stale task-tree commit evidence`
  Children: `TASK-TREE-COMMIT-EVIDENCE-TRUTH-SYNC.1`,
  `TASK-TREE-COMMIT-EVIDENCE-TRUTH-SYNC.2`

- ID: `TASK-TREE-COMMIT-EVIDENCE-TRUTH-SYNC.1`
  Status: `done`
  Goal: `select the task-tree commit-evidence truth-sync slice`
  Acceptance: `Create the active task tree, record the stale evidence class,
  set the implementation frontier, and update live docs without behavior
  changes`
  Verification: `feature-backlog/live-book/book matrix audits; mdBook build; git diff check`
  Commit: `TASK-TREE-COMMIT-EVIDENCE-TRUTH-SYNC.1: select task evidence truth sync`

- ID: `TASK-TREE-COMMIT-EVIDENCE-TRUTH-SYNC.2`
  Status: `pending`
  Goal: `synchronize stale commit evidence across completed task trees`
  Acceptance: `Completed task files no longer carry stale pending commit
  evidence except for explicitly justified placeholders`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `TASK-TREE-COMMIT-EVIDENCE-TRUTH-SYNC.2` | `pending` | `The selection leaf is complete; the next step is the bounded evidence audit and repair.` |

## Decisions

- `2026-05-25`: Treat this as roadmap maintenance because stale commit evidence
  affects recovery and review truth but does not change compiler behavior.
- `2026-05-25`: Keep the repair limited to completed task-tree files and leave
  templates/workflow examples untouched.

## Open Questions

- None for the selection leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `TASK-TREE-COMMIT-EVIDENCE-TRUTH-SYNC.1` | `prove -Iperl t/1303-isf-public-live-book-paths-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t` | `passed: Files=3, Tests=351` |
| `2026-05-25` | `TASK-TREE-COMMIT-EVIDENCE-TRUTH-SYNC.1` | `mdbook build docs/book` | `passed` |
| `2026-05-25` | `TASK-TREE-COMMIT-EVIDENCE-TRUTH-SYNC.1` | `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `TASK-TREE-COMMIT-EVIDENCE-TRUTH-SYNC.1` | `TASK-TREE-COMMIT-EVIDENCE-TRUTH-SYNC.1: select task evidence truth sync` | `selection slice` |
| `TASK-TREE-COMMIT-EVIDENCE-TRUTH-SYNC.2` | `pending` | `implementation slice` |

## Changelog

- `2026-05-25`: Created and activated the task tree.
