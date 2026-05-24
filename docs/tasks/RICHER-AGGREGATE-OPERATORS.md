# RICHER-AGGREGATE-OPERATORS: Richer Aggregate Operators

## Metadata

- Tree ID: `RICHER-AGGREGATE-OPERATORS`
- Status: `active`
- Roadmap lane: `aggregate types and data`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Determine and implement the next safe aggregate-operator widening beyond the
currently shipped matching-shape leafwise numeric and bitwise parameter/generic
expression family.

## Non-Goals

- Do not add broad aggregate operator semantics in one slice.
- Do not accept mixed scalar/aggregate operands without an explicit contract.
- Do not accept mismatched list/record shapes.
- Do not change VHDL aggregate lowering under this tree.
- Do not add backend-rendered raw aggregate operators when a front-end fold or
  typed IR contract is required.
- Do not change ISF aggregate expression behavior until a leaf names one exact
  ISF source position and synchronization scope.

## Acceptance Criteria

- The current aggregate-operator boundary is audited across direct `.fsm`,
  composition parameter/generic values, ISF aggregate expression contexts,
  tests, corpus accounting, mdBook, and live docs.
- Each behavior-bearing leaf names one exact source position, operator family,
  operand/result contract, and failure mode before code changes begin.
- Shipped behavior and remaining deferrals are documented in the mdBook and
  live docs in the same slice as implementation.
- Focused validation covers accepted, rejected, and still-deferred cases for
  the changed surface.
- Broader validation runs when a leaf touches shared expression parsing,
  aggregate type contracts, parameter/generic folding, ISF lowering, or HDL
  emission.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `RICHER-AGGREGATE-OPERATORS`
  Status: `active`
  Goal: `Widen aggregate operators only where the type/shape/result contract is exact.`
  Children: `RICHER-AGGREGATE-OPERATORS.1`,
    `RICHER-AGGREGATE-OPERATORS.2`

- ID: `RICHER-AGGREGATE-OPERATORS.1`
  Status: `done`
  Goal: `Select the task tree and establish the first executable frontier.`
  Acceptance: `The active tree, roadmap status, live docs, mdBook backlog owner stance, and README index name this tree, and the next leaf is limited to an audit/design boundary before behavior changes.`
  Verification: `passed: feature-backlog audit, mdBook build, and diff check`
  Commit: `RICHER-AGGREGATE-OPERATORS.1: select aggregate operator work`

- ID: `RICHER-AGGREGATE-OPERATORS.2`
  Status: `pending`
  Goal: `Audit shipped aggregate operator handling and choose one bounded implementation or close-out surface.`
  Acceptance: `The audit identifies current parser/folder/lowering paths, supported and deferred operator families, relevant tests/docs/corpus entries, and one bounded next implementation leaf or a documented close-out decision. No behavior changes are made in this audit leaf.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `RICHER-AGGREGATE-OPERATORS.2` | `pending` | Matching-shape leafwise aggregate parameter/generic operators are shipped, but richer operator semantics must be audited before any behavior-bearing widening. |

## Decisions

- `2026-05-24`: The first executable leaf is an audit/design slice. Aggregate
  operator widening can affect expression parsing, parameter/generic folding,
  aggregate shape compatibility, ISF lowering, diagnostics, and future backend
  portability, so implementation must first select one source position and
  exact type/shape/result contract.

## Open Questions

- Whether the next safe surface is another parameter/generic operator family,
  direct `.fsm` runtime aggregate expressions, or a narrow ISF aggregate
  expression context is the active `.2` audit question.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `RICHER-AGGREGATE-OPERATORS.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: feature-backlog audit Files=1, Tests=15` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `RICHER-AGGREGATE-OPERATORS.1` | `RICHER-AGGREGATE-OPERATORS.1: select aggregate operator work` | `selection slice` |
| `RICHER-AGGREGATE-OPERATORS.2` | `pending` | `audit/design slice` |

## Changelog

- `2026-05-24`: Created active task tree and selected the audit/design
  frontier.
