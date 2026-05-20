# EXPR-AST-UTILS-OWNER-CONSOLIDATION: Backend AST Utils Ownership

## Metadata

- Tree ID: `EXPR-AST-UTILS-OWNER-CONSOLIDATION`
- Status: `done`
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
  Status: `done`
  Goal: `Make backend AST utils ownership single and correct.`
  Children: `EXPR-AST-UTILS-OWNER-CONSOLIDATION.1`,
  `EXPR-AST-UTILS-OWNER-CONSOLIDATION.2`

- ID: `EXPR-AST-UTILS-OWNER-CONSOLIDATION.1`
  Status: `done`
  Goal: `Select owner shape for the duplicate AST utils packages.`
  Acceptance: `The task file records whether to delete the standalone file,
  keep it as a shim, or move the in-file package, with validation scope.`
  Verification: `static import audit`; `git diff --check`; `mdbook build docs/book`
  Commit: `EXPR-AST-UTILS-OWNER-CONSOLIDATION.1: select AST utils owner`

- ID: `EXPR-AST-UTILS-OWNER-CONSOLIDATION.2`
  Status: `done`
  Goal: `Implement the selected backend AST utils owner cleanup.`
  Acceptance: `Duplicate/broken constructor ownership is removed or corrected
  without changing generated HDL.`
  Verification: `static import audit plus focused backend AST/enable-graph tests passed`
  Commit: `EXPR-AST-UTILS-OWNER-CONSOLIDATION.2: remove duplicate AST utils file`

## Current Frontier

This tree is closed. The standalone `perl/FSM/AST/Utils.pm` duplicate was
removed. The in-file `FSM::AST::Utils` package in
[perl/FSM/AST/Node.pm](../../perl/FSM/AST/Node.pm) is the sole live backend
AST constructor owner.

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `EXPR-AST-UTILS-OWNER-CONSOLIDATION.1` | `done` | Selected deletion of the standalone duplicate. |
| 2 | `EXPR-AST-UTILS-OWNER-CONSOLIDATION.2` | `done` | Removed the duplicate source file and validated live backend callers. |

## Decisions

- `2026-05-20`: Created from `IR-EXPRESSION-AST-OWNERSHIP.3` because the repo
  has two tracked `FSM::AST::Utils` package definitions, and the standalone
  one references class names that do not match the actual `FSM::AST::*`
  classes.
- `2026-05-20`: Selected deletion of the standalone
  `perl/FSM/AST/Utils.pm` file rather than a shim.
  Static search found no live `use FSM::AST::Utils` or
  `require FSM::AST::Utils` path outside the file itself. Current backend
  callers load [perl/FSM/AST/Node.pm](../../perl/FSM/AST/Node.pm), which
  defines the working in-file `FSM::AST::Utils` package. The standalone file
  is not only duplicate ownership; its constructors refer to nonexistent
  `FSM::AST::Node::*` classes and use a binary-constructor argument order that
  does not match `FSM::AST::BinaryOp`.
- `2026-05-20`: `.2` must delete the standalone file, prove no runtime/test
  path imports it directly, compile the live `Node.pm` owner, and run focused
  enable-graph/backend AST caller tests. Generated HDL is expected to remain
  unchanged because live callers already use the in-file owner.
- `2026-05-20`: Removed the standalone `perl/FSM/AST/Utils.pm` source file.
  The only remaining `FSM::AST::Utils` package definition is now in
  [perl/FSM/AST/Node.pm](../../perl/FSM/AST/Node.pm).

## Open Questions

- None for the selected owner shape.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `EXPR-AST-UTILS-OWNER-CONSOLIDATION.1` | `rg -n '^use FSM::AST::Utils|^require FSM::AST::Utils|package FSM::AST::Utils' perl t bin`; `git diff --check`; `mdbook build docs/book` | `passed` |
| `2026-05-20` | `EXPR-AST-UTILS-OWNER-CONSOLIDATION.2` | `rg -n '^use FSM::AST::Utils|^require FSM::AST::Utils|package FSM::AST::Utils' perl t bin`; `perl -Iperl -c perl/FSM/AST/Node.pm`; `prove -Iperl t/206-enable-graph-enable-support.t t/208-enable-graph-ast-support.t t/210-enable-graph-factorization-policy-support.t t/231-systemverilog-consolidated-intermediate-stage-support.t`; `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `EXPR-AST-UTILS-OWNER-CONSOLIDATION.1` | `EXPR-AST-UTILS-OWNER-CONSOLIDATION.1: select AST utils owner` | Selects standalone-file deletion; `.2` owns implementation. |
| `EXPR-AST-UTILS-OWNER-CONSOLIDATION.2` | `EXPR-AST-UTILS-OWNER-CONSOLIDATION.2: remove duplicate AST utils file` | Removes the standalone duplicate; `Node.pm` remains the sole owner. |

## Changelog

- `2026-05-20`: Created proposed follow-up task tree from
  `IR-EXPRESSION-AST-OWNERSHIP.3`.
- `2026-05-20`: Activated `.1`, selected the in-file `FSM::AST::Utils`
  package in `Node.pm` as the sole live owner, and advanced `.2` for source
  cleanup.
- `2026-05-20`: Completed `.2` by deleting the standalone duplicate and
  closing the tree.
