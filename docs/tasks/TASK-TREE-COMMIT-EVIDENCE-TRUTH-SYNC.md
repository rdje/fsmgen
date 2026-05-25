# TASK-TREE-COMMIT-EVIDENCE-TRUTH-SYNC: Task-Tree Commit Evidence Truth Sync

## Metadata

- Tree ID: `TASK-TREE-COMMIT-EVIDENCE-TRUTH-SYNC`
- Status: `done`
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
- Any remaining `pending` wording is either descriptive repair-scope prose,
  templates/workflow examples, semantic feature wording, or explicitly
  justified.
- Focused text audits, `mdbook build docs/book`, and `git diff --check` pass.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `TASK-TREE-COMMIT-EVIDENCE-TRUTH-SYNC`
  Status: `done`
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
  Commit: `1c0163a9 TASK-TREE-COMMIT-EVIDENCE-TRUTH-SYNC.1: select task evidence truth sync`

- ID: `TASK-TREE-COMMIT-EVIDENCE-TRUTH-SYNC.2`
  Status: `done`
  Goal: `synchronize stale commit evidence across completed task trees`
  Acceptance: `Completed task files no longer carry stale pending commit
  evidence except for explicitly justified placeholders`
  Verification: `stale-evidence field audit; malformed-row audit; feature-backlog/live-book/book matrix audits; mdBook build; git diff check`
  Commit: `TASK-TREE-COMMIT-EVIDENCE-TRUTH-SYNC.2: sync completed task evidence`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `Stale completed task-tree commit evidence has been synchronized.` |

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
| `2026-05-25` | `TASK-TREE-COMMIT-EVIDENCE-TRUTH-SYNC.2` | `rg stale-evidence field audit` | `passed: no stale commit-evidence field matches` |
| `2026-05-25` | `TASK-TREE-COMMIT-EVIDENCE-TRUTH-SYNC.2` | `rg malformed-row audit` | `passed: no malformed empty commit-log rows` |
| `2026-05-25` | `TASK-TREE-COMMIT-EVIDENCE-TRUTH-SYNC.2` | `prove -Iperl t/1303-isf-public-live-book-paths-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t` | `passed: Files=3, Tests=351` |
| `2026-05-25` | `TASK-TREE-COMMIT-EVIDENCE-TRUTH-SYNC.2` | `mdbook build docs/book` | `passed` |
| `2026-05-25` | `TASK-TREE-COMMIT-EVIDENCE-TRUTH-SYNC.2` | `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `TASK-TREE-COMMIT-EVIDENCE-TRUTH-SYNC.1` | `1c0163a9 TASK-TREE-COMMIT-EVIDENCE-TRUTH-SYNC.1: select task evidence truth sync` | `selection slice` |
| `TASK-TREE-COMMIT-EVIDENCE-TRUTH-SYNC.2` | `TASK-TREE-COMMIT-EVIDENCE-TRUTH-SYNC.2: sync completed task evidence` | `implementation slice` |

## Changelog

- `2026-05-25`: Created and activated the task tree.
- `2026-05-25`: Synchronized stale completed task-tree commit evidence and
  closed the task tree.
