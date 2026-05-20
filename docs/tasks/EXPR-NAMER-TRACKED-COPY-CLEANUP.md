# EXPR-NAMER-TRACKED-COPY-CLEANUP: ExpressionNamer Tracked Copy Cleanup

## Metadata

- Tree ID: `EXPR-NAMER-TRACKED-COPY-CLEANUP`
- Status: `done`
- Roadmap lane: `architecture backlog`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Remove the formerly tracked `perl/FSM/ExpressionNamer.pm.new` package
duplicate so review has one obvious `FSM::ExpressionNamer` source of truth.

## Non-Goals

- Do not change live `FSM::ExpressionNamer` behavior.
- Do not modify expression naming semantics.
- Do not remove any file until static references and repository intent are
  checked in the owning leaf.

## Acceptance Criteria

- Static search proves whether `ExpressionNamer.pm.new` has any live
  references.
- The selected action removes the source-of-truth ambiguity or records a
  non-package-bearing archival role.
- Focused validation proves live `FSM::ExpressionNamer` still loads and the
  existing expression-namer tests still pass.
- Live docs and task-tree status are synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `EXPR-NAMER-TRACKED-COPY-CLEANUP`
  Status: `done`
  Goal: `Clean up the tracked ExpressionNamer duplicate.`
  Children: `EXPR-NAMER-TRACKED-COPY-CLEANUP.1`

- ID: `EXPR-NAMER-TRACKED-COPY-CLEANUP.1`
  Status: `done`
  Goal: `Remove or reclassify ExpressionNamer.pm.new.`
  Acceptance: `The tracked duplicate no longer creates package-level source
  ambiguity, and focused expression-namer validation passes.`
  Verification: `static reference audit plus focused expression-namer checks passed`
  Commit: `EXPR-NAMER-TRACKED-COPY-CLEANUP.1: remove tracked ExpressionNamer copy`

## Current Frontier

This tree is closed. The tracked duplicate was removed after static search
confirmed no live load/reference outside documentation.

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `EXPR-NAMER-TRACKED-COPY-CLEANUP.1` | `done` | The tracked duplicate source file was removed. |

## Decisions

- `2026-05-20`: Created from `IR-EXPRESSION-AST-OWNERSHIP.3` because static
  search found no references loading `ExpressionNamer.pm.new`, but it declares
  the same package name as the live module.
- `2026-05-20`: Selected removal rather than archival reclassification because
  no runtime or test path loads the duplicate, while the live module remains
  [perl/FSM/ExpressionNamer.pm](../../perl/FSM/ExpressionNamer.pm).
- `2026-05-20`: Removed the formerly tracked
  `perl/FSM/ExpressionNamer.pm.new` source file. The live owner remains
  [perl/FSM/ExpressionNamer.pm](../../perl/FSM/ExpressionNamer.pm).

## Open Questions

- None for the active removal leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `EXPR-NAMER-TRACKED-COPY-CLEANUP.1` | `rg -n 'ExpressionNamer\.pm\.new' perl t bin`; `perl -Iperl -c perl/FSM/ExpressionNamer.pm`; `prove -Iperl t/520-expression-namer-query-defensive-copy-boundary-audit.t`; `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `EXPR-NAMER-TRACKED-COPY-CLEANUP.1` | `EXPR-NAMER-TRACKED-COPY-CLEANUP.1: remove tracked ExpressionNamer copy` | Removes the duplicate package file; live owner remains `perl/FSM/ExpressionNamer.pm`. |

## Changelog

- `2026-05-20`: Created proposed follow-up task tree from
  `IR-EXPRESSION-AST-OWNERSHIP.3`.
- `2026-05-20`: Activated `.1`, removed the duplicate source file, and closed
  the tree after focused validation.
