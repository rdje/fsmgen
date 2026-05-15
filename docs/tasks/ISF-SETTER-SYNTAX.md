# ISF-SETTER-SYNTAX: Scalar Setter Syntax Unification

## Metadata

- Tree ID: `ISF-SETTER-SYNTAX`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-15`
- Last updated: `2026-05-15`
- Owner: repo-local workflow

## Goal

Ship one explicit scalar setter spelling, `(set lhs expr)`, that is accepted
in both rule action contexts and transaction body contexts while preserving
the different runtime regions underneath.

## Non-Goals

- Do not remove existing rule shorthand `(lhs expr)`.
- Do not remove existing transaction `(update lhs expr)`.
- Do not add combinational transaction assignment semantics.
- Do not widen setter targets to aggregates, bank entries, or actor inputs in
  this slice.

## Acceptance Criteria

- Transaction bodies accept `(set lhs expr)` wherever `(update lhs expr)` is
  currently accepted, including shipped nested body contexts.
- Rule bodies accept `(set lhs expr)` as an explicit assignment action while
  preserving existing `(lhs expr)` shorthand.
- Lowered `.fsm` behavior is unchanged by context: rule `set` lowers inside
  the rule non-state DT DTE, and transaction `set` lowers as an ordered
  flopped transaction state.
- Malformed `set` clauses fail closed with targeted diagnostics.
- The mdBook, ISF spec, public contract docs, roadmap/task-tree state, and
  live docs are synchronized.
- Focused regressions and the ISF quick/broader gate pass.

## Task Tree

- ID: `ISF-SETTER-SYNTAX`
  Status: `done`
  Goal: `Ship explicit scalar set syntax across rules and transactions.`
  Children: `ISF-SETTER-SYNTAX.1`

- ID: `ISF-SETTER-SYNTAX.1`
  Status: `done`
  Goal: `Implement and document explicit (set lhs expr) syntax.`
  Acceptance: Parser and scheduler accept well-formed rule and transaction
  `set` forms, reject malformed forms, preserve existing assignment timing,
  update public documentation/contract metadata, and pass focused plus ISF
  regression checks.
  Verification: `passed`
  Commit: `ISF-SETTER-SYNTAX.1: ship scalar set syntax`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| - | `closed` | `done` | `ISF-SETTER-SYNTAX.1` completed the tree. |

## Decisions

- `2026-05-15`: Use `(set lhs expr)` as the canonical explicit setter
  spelling because it is short, reads naturally in both rules and
  transactions, and does not imply a new timing region.
- `2026-05-15`: Keep existing `(update lhs expr)` and rule `(lhs expr)`
  spellings as supported aliases/shorthand while ISF remains a live evolving
  surface.
- `2026-05-15`: `set` timing is context-owned. In rules it lowers like the
  current flopped rule assignment under the rule DT DTE. In transactions it
  lowers like `update`, as one ordered flopped transaction state.

## Open Questions

- None for the first scalar setter slice.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-15` | `ISF-SETTER-SYNTAX.1` | Syntax checks for modified Perl modules/tests; `prove -I perl t/1180-isf-unsupported-transaction-clause-boundary.t t/1229-isf-compatibility-cli-parity.t t/1246-isf-setter-syntax.t t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-SETTER-SYNTAX.1` | `ISF-SETTER-SYNTAX.1: ship scalar set syntax` | Scalar setter syntax shipped and tree closed. |

## Changelog

- `2026-05-15`: Created the scalar setter syntax task tree from the mdBook
  backlog item and earlier rule/transaction setter discussion.
- `2026-05-15`: Started `ISF-SETTER-SYNTAX.1`.
- `2026-05-15`: Completed `ISF-SETTER-SYNTAX.1` and closed the tree.
