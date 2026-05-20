# EXPR-AST-UTILS-OWNER-CONSOLIDATION: Backend AST Utils Ownership

## Metadata

- Tree ID: `EXPR-AST-UTILS-OWNER-CONSOLIDATION`
- Status: `proposed`
- Roadmap lane: `architecture backlog`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Collapse the duplicate `FSM::AST::Utils` ownership surface into one correct,
reviewable backend AST constructor boundary.

## Non-Goals

- Do not change backend enable semantics.
- Do not change the `FSM::AST::*` node class names without a dedicated
  migration leaf.
- Do not replace direct `CoreAST` expression construction.

## Acceptance Criteria

- There is one documented backend AST utility owner, or the standalone file is
  a correct compatibility shim over that owner.
- Constructor helpers instantiate the actual `FSM::AST::*` classes defined in
  [perl/FSM/AST/Node.pm](../../perl/FSM/AST/Node.pm).
- Focused syntax/tests cover both the owner and current backend callers.
- Live docs and task status reflect the selected ownership boundary.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `EXPR-AST-UTILS-OWNER-CONSOLIDATION`
  Status: `proposed`
  Goal: `Make backend AST utils ownership single and correct.`
  Children: `EXPR-AST-UTILS-OWNER-CONSOLIDATION.1`,
  `EXPR-AST-UTILS-OWNER-CONSOLIDATION.2`

- ID: `EXPR-AST-UTILS-OWNER-CONSOLIDATION.1`
  Status: `proposed`
  Goal: `Select owner shape for the duplicate AST utils packages.`
  Acceptance: `The task file records whether to delete the standalone file,
  keep it as a shim, or move the in-file package, with validation scope.`
  Verification: `pending`
  Commit: `pending`

- ID: `EXPR-AST-UTILS-OWNER-CONSOLIDATION.2`
  Status: `proposed`
  Goal: `Implement the selected backend AST utils owner cleanup.`
  Acceptance: `Duplicate/broken constructor ownership is removed or corrected
  without changing generated HDL.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

This tree is proposed, not active. Activate it before editing
[perl/FSM/AST/Node.pm](../../perl/FSM/AST/Node.pm) or
[perl/FSM/AST/Utils.pm](../../perl/FSM/AST/Utils.pm).

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `EXPR-AST-UTILS-OWNER-CONSOLIDATION.1` | `proposed` | The owner shape must be selected before a source cleanup. |

## Decisions

- `2026-05-20`: Created from `IR-EXPRESSION-AST-OWNERSHIP.3` because the repo
  has two tracked `FSM::AST::Utils` package definitions, and the standalone
  one references class names that do not match the actual `FSM::AST::*`
  classes.

## Open Questions

- Is deleting the standalone file enough, or does any user/test path require a
  compatibility shim?

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `EXPR-AST-UTILS-OWNER-CONSOLIDATION.1` | `pending` | `pending` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `EXPR-AST-UTILS-OWNER-CONSOLIDATION.1` | `pending` | `pending` |

## Changelog

- `2026-05-20`: Created proposed follow-up task tree from
  `IR-EXPRESSION-AST-OWNERSHIP.3`.
