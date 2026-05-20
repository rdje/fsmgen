# EXPR-NAMER-TRACKED-COPY-CLEANUP: ExpressionNamer Tracked Copy Cleanup

## Metadata

- Tree ID: `EXPR-NAMER-TRACKED-COPY-CLEANUP`
- Status: `proposed`
- Roadmap lane: `architecture backlog`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Remove or explicitly reclassify the tracked
[perl/FSM/ExpressionNamer.pm.new](../../perl/FSM/ExpressionNamer.pm.new)
package duplicate so review has one obvious `FSM::ExpressionNamer` source of
truth.

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
  Status: `proposed`
  Goal: `Clean up the tracked ExpressionNamer duplicate.`
  Children: `EXPR-NAMER-TRACKED-COPY-CLEANUP.1`

- ID: `EXPR-NAMER-TRACKED-COPY-CLEANUP.1`
  Status: `proposed`
  Goal: `Remove or reclassify ExpressionNamer.pm.new.`
  Acceptance: `The tracked duplicate no longer creates package-level source
  ambiguity, and focused expression-namer validation passes.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

This tree is proposed, not active. Activate it before editing or removing
[perl/FSM/ExpressionNamer.pm.new](../../perl/FSM/ExpressionNamer.pm.new).

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `EXPR-NAMER-TRACKED-COPY-CLEANUP.1` | `proposed` | This is the smallest concrete expression ownership cleanup. |

## Decisions

- `2026-05-20`: Created from `IR-EXPRESSION-AST-OWNERSHIP.3` because static
  search found no references loading `ExpressionNamer.pm.new`, but it declares
  the same package name as the live module.

## Open Questions

- Should the duplicate be removed outright, or does the user want it preserved
  as non-source archival material?

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `EXPR-NAMER-TRACKED-COPY-CLEANUP.1` | `pending` | `pending` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `EXPR-NAMER-TRACKED-COPY-CLEANUP.1` | `pending` | `pending` |

## Changelog

- `2026-05-20`: Created proposed follow-up task tree from
  `IR-EXPRESSION-AST-OWNERSHIP.3`.
