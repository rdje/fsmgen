# TASK-TREE-THIS-COMMIT-EVIDENCE-TRUTH-SYNC: Task-Tree This-Commit Evidence Truth Sync

## Metadata

- Tree ID: `TASK-TREE-THIS-COMMIT-EVIDENCE-TRUTH-SYNC`
- Status: `done`
- Roadmap lane: `roadmap maintenance`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Replace stale `this commit` completion placeholders and stale `final gate
pending` verification wording in completed task-tree files with concrete
completion subjects or commit references.

## Non-Goals

- Do not change parser, scheduler, emitter, generated artifact, HDL, CLI,
  public API, or runtime behavior.
- Do not reopen completed task trees.
- Do not rewrite semantic feature wording that happens to contain the word
  `pending`.
- Do not edit `docs/tasks/TEMPLATE.md` placeholder examples or
  `docs/TASK_TREE.md` workflow examples.

## Acceptance Criteria

- The task tree is selected before `this commit` evidence repair edits begin.
- Completed task files with stale `this commit` commit evidence are audited.
- Completed task files with stale `final gate pending` verification evidence
  are audited.
- Recoverable stale evidence is replaced by concrete completion subjects or
  commit references without changing the task outcome.
- Focused text audits, `mdbook build docs/book`, and `git diff --check` pass.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `TASK-TREE-THIS-COMMIT-EVIDENCE-TRUTH-SYNC`
  Status: `done`
  Goal: `synchronize stale this-commit task-tree evidence`
  Children: `TASK-TREE-THIS-COMMIT-EVIDENCE-TRUTH-SYNC.1`,
  `TASK-TREE-THIS-COMMIT-EVIDENCE-TRUTH-SYNC.2`

- ID: `TASK-TREE-THIS-COMMIT-EVIDENCE-TRUTH-SYNC.1`
  Status: `done`
  Goal: `select the this-commit evidence truth-sync slice`
  Acceptance: `Create the active task tree, record the stale evidence class,
  set the implementation frontier, and update live docs without behavior
  changes`
  Verification: `feature-backlog/live-book/book matrix audits; mdBook build; git diff check`
  Commit: `edfe91f8 TASK-TREE-THIS-COMMIT-EVIDENCE-TRUTH-SYNC.1: select this-commit evidence sync`

- ID: `TASK-TREE-THIS-COMMIT-EVIDENCE-TRUTH-SYNC.2`
  Status: `done`
  Goal: `synchronize stale this-commit and final-gate evidence`
  Acceptance: `Completed task files no longer carry stale this-commit commit
  evidence or stale final-gate-pending verification evidence`
  Verification: `this-commit/final-gate field audit; feature-backlog/live-book/book matrix audits; mdBook build; git diff check`
  Commit: `TASK-TREE-THIS-COMMIT-EVIDENCE-TRUTH-SYNC.2: sync this-commit evidence`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `Stale this-commit and final-gate task-tree evidence has been synchronized.` |

## Decisions

- `2026-05-25`: Treat `this commit` placeholders as a separate evidence class
  from the stale `pending commit` placeholders already repaired by
  `TASK-TREE-COMMIT-EVIDENCE-TRUTH-SYNC`.
- `2026-05-25`: Prefer the git commit whose subject starts with the leaf ID
  when resolving a stale placeholder; later maintenance commits may mention
  the same leaf ID but are not the original completion evidence.

## Open Questions

- None for the selection leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `TASK-TREE-THIS-COMMIT-EVIDENCE-TRUTH-SYNC.1` | `prove -Iperl t/1303-isf-public-live-book-paths-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t` | `passed: Files=3, Tests=351` |
| `2026-05-25` | `TASK-TREE-THIS-COMMIT-EVIDENCE-TRUTH-SYNC.1` | `mdbook build docs/book` | `passed` |
| `2026-05-25` | `TASK-TREE-THIS-COMMIT-EVIDENCE-TRUTH-SYNC.1` | `git diff --check` | `passed` |
| `2026-05-25` | `TASK-TREE-THIS-COMMIT-EVIDENCE-TRUTH-SYNC.2` | `rg this-commit/final-gate field audit` | `passed: no stale evidence field matches` |
| `2026-05-25` | `TASK-TREE-THIS-COMMIT-EVIDENCE-TRUTH-SYNC.2` | `prove -Iperl t/1303-isf-public-live-book-paths-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t` | `passed: Files=3, Tests=351` |
| `2026-05-25` | `TASK-TREE-THIS-COMMIT-EVIDENCE-TRUTH-SYNC.2` | `mdbook build docs/book` | `passed` |
| `2026-05-25` | `TASK-TREE-THIS-COMMIT-EVIDENCE-TRUTH-SYNC.2` | `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `TASK-TREE-THIS-COMMIT-EVIDENCE-TRUTH-SYNC.1` | `edfe91f8 TASK-TREE-THIS-COMMIT-EVIDENCE-TRUTH-SYNC.1: select this-commit evidence sync` | `selection slice` |
| `TASK-TREE-THIS-COMMIT-EVIDENCE-TRUTH-SYNC.2` | `TASK-TREE-THIS-COMMIT-EVIDENCE-TRUTH-SYNC.2: sync this-commit evidence` | `implementation slice` |

## Changelog

- `2026-05-25`: Created and activated the task tree.
- `2026-05-25`: Synchronized stale this-commit/final-gate evidence and closed
  the task tree.
