# RICHER-AGGREGATE-OPERATORS: Richer Aggregate Operators

## Metadata

- Tree ID: `RICHER-AGGREGATE-OPERATORS`
- Status: `done`
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
  Status: `done`
  Goal: `Widen aggregate operators only where the type/shape/result contract is exact.`
  Children: `RICHER-AGGREGATE-OPERATORS.1`,
    `RICHER-AGGREGATE-OPERATORS.2`,
    `RICHER-AGGREGATE-OPERATORS.3`

- ID: `RICHER-AGGREGATE-OPERATORS.1`
  Status: `done`
  Goal: `Select the task tree and establish the first executable frontier.`
  Acceptance: `The active tree, roadmap status, live docs, mdBook backlog owner stance, and README index name this tree, and the next leaf is limited to an audit/design boundary before behavior changes.`
  Verification: `passed: feature-backlog audit, mdBook build, and diff check`
  Commit: `RICHER-AGGREGATE-OPERATORS.1: select aggregate operator work`

- ID: `RICHER-AGGREGATE-OPERATORS.2`
  Status: `done`
  Goal: `Audit shipped aggregate operator handling and choose one bounded implementation or close-out surface.`
  Acceptance: `The audit identifies current parser/folder/lowering paths, supported and deferred operator families, relevant tests/docs/corpus entries, and one bounded next implementation leaf or a documented close-out decision. No behavior changes are made in this audit leaf.`
  Verification: `passed: focused aggregate parameter/operator and ISF deferral tests, feature-backlog audit, mdBook build, and diff check`
  Commit: `RICHER-AGGREGATE-OPERATORS.2: audit aggregate operator frontier`

- ID: `RICHER-AGGREGATE-OPERATORS.3`
  Status: `done`
  Goal: `Implement unary bitwise aggregate complement for semantic parameter/generic values.`
  Acceptance: `Direct +params, .rtlif defaults, external RTL overrides, and generated-child overrides accept a single aggregate operand through (~ VALUE) and (not VALUE), fold each scalar leaf by bitwise complement with unchanged aggregate shape and leaf width, reject scalar operands and bad arity with targeted diagnostics, and keep ISF runtime aggregate-to-aggregate expressions deferred.`
  Verification: `passed: focused direct/composition/corpus tests, supported-corpus gates, feature-backlog audit, mdBook build, and diff check`
  Commit: `RICHER-AGGREGATE-OPERATORS.3: ship aggregate unary complement`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `RICHER-AGGREGATE-OPERATORS.3` shipped the bounded unary complement widening and closed this tree. |

## Decisions

- `2026-05-24`: The first executable leaf is an audit/design slice. Aggregate
  operator widening can affect expression parsing, parameter/generic folding,
  aggregate shape compatibility, ISF lowering, diagnostics, and future backend
  portability, so implementation must first select one source position and
  exact type/shape/result contract.
- `2026-05-24`: The audit selected unary bitwise aggregate complement as the
  next bounded implementation. The shipped aggregate operator implementation
  already folds semantic parameter/generic aggregate values before HDL
  lowering, so `(~ VALUE)` / `(not VALUE)` can preserve the operand's
  list/record shape and invert only scalar leaves without introducing runtime
  aggregate scheduling or backend-rendered aggregate operators.
- `2026-05-24`: The implementation shipped unary bitwise aggregate
  complement only in the semantic parameter/generic value path. The operator
  accepts exactly one aggregate operand, preserves the operand list/record
  shape and scalar leaf widths, and folds to an ordinary aggregate value
  before HDL lowering.

## Audit Result

Current shipped aggregate operator support lives in
`FSM::ParameterValueSupport`. It normalizes semantic parameter/generic values
for direct `+params`, `.rtlif` defaults, external RTL parameter overrides, and
generated-child parameter overrides. When an expression operand resolves to an
aggregate value, the current implementation requires all operands to be
aggregate values with matching list/record shape and folds leafwise `+`, `-`,
`*`, `/`, `%`, `&`, `|`, and `^` plus `add`, `sub`, `mul`, `div`, `mod`,
`and`, `or`, and `xor` aliases before HDL lowering.

Supported audited surfaces:

- Direct `.fsm` parameter/generic aggregate expressions in `+params`.
- External `.rtlif` parameter/generic defaults.
- External RTL `?rtl` parameter override expressions.
- Generated-child `?fsmc` / `?dtc` parameter override expressions.
- Matching nested list/record shapes with fixed-width unsigned scalar leaves,
  overflow/underflow rejection, and divide/modulo-by-zero rejection.

Still-deferred surfaces:

- Mixed scalar/aggregate aggregate operators.
- Mismatched list/record shapes.
- Runtime direct `.fsm` aggregate-to-aggregate operator expressions.
- ISF runtime subaggregate operands and aggregate paths in expression-operator
  position.
- VHDL aggregate lowering and backend-rendered aggregate operators.

Selected next leaf:

- `RICHER-AGGREGATE-OPERATORS.3` will implement unary bitwise aggregate
  complement only in the existing semantic parameter/generic value path.
  Accepted syntax is `(~ VALUE)` and `(not VALUE)`. The result keeps the same
  list/record shape and scalar leaf widths. Scalar operands, multiple
  operands, zero operands, and ISF runtime aggregate-to-aggregate expressions
  remain rejected.

## Implementation Result

`RICHER-AGGREGATE-OPERATORS.3` extends `FSM::ParameterValueSupport` so
semantic parameter/generic aggregate values accept unary bitwise complement in
direct `+params`, `.rtlif` parameter defaults, external RTL parameter
overrides, and generated-child parameter overrides. Both `(~ VALUE)` and
`(not VALUE)` normalize to the same operator.

The implementation preserves the established fold-before-HDL contract: the
operand must resolve to one list or record aggregate payload, each scalar leaf
is inverted at its declared width, and the result keeps the same aggregate
shape. Scalar operands, zero operands, and unparenthesized multiple operands
fail before HDL generation with targeted diagnostics. Runtime direct `.fsm`
aggregate-to-aggregate expressions, ISF runtime subaggregate operands,
aggregate paths in expression-operator position, mixed scalar/aggregate
operators, mismatched aggregate shapes, VHDL aggregate lowering, and
backend-rendered aggregate operators remain deferred.

## Open Questions

- None. This tree is closed.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `RICHER-AGGREGATE-OPERATORS.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: feature-backlog audit Files=1, Tests=15` |
| `2026-05-24` | `RICHER-AGGREGATE-OPERATORS.2` | `prove -Iperl t/30-language-contract-symbol-definitions.t t/51-language-contract-symbol-definition-boundary.t t/91-composition-multi-rtl-children.t t/292-composition-generated-child-parameter-overrides.t t/1262-isf-aggregate-storage-leaf-expression-reads.t t/1284-isf-aggregate-rule-expression-values.t t/1288-isf-aggregate-drive-expression-values.t t/1290-isf-aggregate-drive-call-expression-values.t t/1292-isf-aggregate-inline-drive-expression-values.t`; `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: focused tests Files=9, Tests=174; feature-backlog audit Files=1, Tests=15` |
| `2026-05-24` | `RICHER-AGGREGATE-OPERATORS.3` | `prove -Iperl t/30-language-contract-symbol-definitions.t t/51-language-contract-symbol-definition-boundary.t t/91-composition-multi-rtl-children.t t/292-composition-generated-child-parameter-overrides.t t/248-regression-corpus-accounting.t t/261-regression-corpus-supported-language-features.t`; `prove -Iperl t/296-regression-corpus-supported-behavior.t t/301-check-json-supported-corpus.t t/303-normalized-semantic-json-supported-corpus.t t/297-capability-manifest.t t/359-support-accounting-corpus-runtime-audit.t t/372-support-accounting-catalog-path-audit.t`; `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: focused direct/composition/corpus tests Files=6, Tests=3287; supported-corpus gates Files=6, Tests=27` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `RICHER-AGGREGATE-OPERATORS.1` | `RICHER-AGGREGATE-OPERATORS.1: select aggregate operator work` | `selection slice` |
| `RICHER-AGGREGATE-OPERATORS.2` | `RICHER-AGGREGATE-OPERATORS.2: audit aggregate operator frontier` | `audit/design slice` |
| `RICHER-AGGREGATE-OPERATORS.3` | `RICHER-AGGREGATE-OPERATORS.3: ship aggregate unary complement` | `implementation slice` |

## Changelog

- `2026-05-24`: Created active task tree and selected the audit/design
  frontier.
- `2026-05-24`: Audited the shipped aggregate operator boundary and selected
  unary bitwise aggregate complement in semantic parameter/generic value
  contexts as the next bounded implementation leaf.
- `2026-05-24`: Shipped unary bitwise aggregate complement for semantic
  parameter/generic aggregate values and closed the task tree.
