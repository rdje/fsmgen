# AGGREGATE-AUTOGROWTH-FROM-USAGE: Automatic Aggregate Growth From Usage

## Metadata

- Tree ID: `AGGREGATE-AUTOGROWTH-FROM-USAGE`
- Status: `active`
- Roadmap lane: `aggregate types and data`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Broaden aggregate shape/type inference where FSMGen can recover a safe
list/record shape from authored usage without requiring an explicit aggregate
type anchor.

## Non-Goals

- Do not claim broad aggregate autovivification across every source position
  in one slice.
- Do not make backend-owned struct/record lowering the default under this
  tree.
- Do not widen VHDL aggregate lowering under this tree.
- Do not infer aggregate shapes from ambiguous or conflicting member/index
  usage without a reviewable proof source and fail-closed diagnostics.
- Do not change code before the audit leaf selects one bounded implementation
  surface.

## Acceptance Criteria

- The current aggregate-growth boundary is audited across direct `.fsm`,
  composition, ISF lowering, tests, corpus accounting, mdBook, and live docs.
- Each behavior-bearing leaf names one bounded source position or diagnostic
  family before code changes begin.
- Shipped behavior and remaining deferrals are documented in the mdBook and
  live docs in the same slice as implementation.
- Focused validation covers accepted, rejected, and still-deferred aggregate
  shape inference cases for the changed surface.
- Broader validation runs when a leaf touches shared aggregate typing,
  composition endpoint typing, or HDL lowering paths.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `AGGREGATE-AUTOGROWTH-FROM-USAGE`
  Status: `active`
  Goal: `Broaden safe aggregate shape inference one reviewable surface at a time.`
  Children: `AGGREGATE-AUTOGROWTH-FROM-USAGE.1`,
    `AGGREGATE-AUTOGROWTH-FROM-USAGE.2`,
    `AGGREGATE-AUTOGROWTH-FROM-USAGE.3`,
    `AGGREGATE-AUTOGROWTH-FROM-USAGE.4`,
    `AGGREGATE-AUTOGROWTH-FROM-USAGE.5`

- ID: `AGGREGATE-AUTOGROWTH-FROM-USAGE.1`
  Status: `done`
  Goal: `Select the task tree and establish the first executable frontier.`
  Acceptance: `The active tree, roadmap status, live docs, and backlog owner stance name this tree, and the next leaf is limited to an audit/design boundary before behavior changes.`
  Verification: `passed: live-book/spec/backlog audits, mdBook build, and diff check`
  Commit: `b0f4783e AGGREGATE-AUTOGROWTH-FROM-USAGE.1: select aggregate autogrowth work`

- ID: `AGGREGATE-AUTOGROWTH-FROM-USAGE.2`
  Status: `done`
  Goal: `Audit shipped aggregate-growth behavior and choose the smallest safe implementation surface.`
  Acceptance: `The audit identifies current aggregate inference sources, expected-failure or deferred aggregate source positions, relevant tests/docs, and one bounded next implementation leaf with explicit non-goals.`
  Verification: `passed: focused aggregate/corpus tests, mdBook build, and diff check`
  Commit: `AGGREGATE-AUTOGROWTH-FROM-USAGE.2: audit aggregate autogrowth frontier`

- ID: `AGGREGATE-AUTOGROWTH-FROM-USAGE.3`
  Status: `done`
  Goal: `Infer a direct whole-signal aggregate type contract from a whole aggregate RHS constant.`
  Acceptance: `When a direct .fsm whole-signal LHS has no declared aggregate type and is assigned a whole aggregate constant root whose payload already has one canonical list/record shape, FSMGen preserves that inferred contract on the target signal before HDL generation. Explicit target declarations remain authoritative, non-aggregate RHS expressions stay unchanged, arbitrary member/index autogrowth stays deferred, and incompatible later contracts still fail closed.`
  Verification: `passed: focused direct aggregate autogrowth/corpus tests, supported-corpus behavior/json/manifest/accounting gates, feature-backlog audit, mdBook build, and diff check`
  Commit: `AGGREGATE-AUTOGROWTH-FROM-USAGE.3: infer aggregate constant targets`

- ID: `AGGREGATE-AUTOGROWTH-FROM-USAGE.4`
  Status: `done`
  Goal: `Audit whether direct RHS concat expressions can safely seed undeclared whole-signal list aggregate contracts.`
  Acceptance: `The audit identifies the current RHS concat source-contract implementation, accepted and rejected coverage, ambiguity risks, naming policy implications, and whether the next behavior-bearing leaf should infer a list contract for undeclared whole targets from direct RHS concat. No behavior changes are made in this audit leaf.`
  Verification: `passed: focused concat expression, SystemVerilog operand-contract, corpus accounting, feature-backlog audit, mdBook build, and diff check`
  Commit: `AGGREGATE-AUTOGROWTH-FROM-USAGE.4: audit RHS concat autogrowth`

- ID: `AGGREGATE-AUTOGROWTH-FROM-USAGE.5`
  Status: `pending`
  Goal: `Infer undeclared whole-signal list contracts from direct RHS concat expressions.`
  Acceptance: `When a direct .fsm whole-signal LHS has no explicit declaration and is assigned a direct RHS concat whose operands all have exact scalar or aggregate type specs, FSMGen records a generated list aggregate contract on the target before HDL generation. Nested concat operands preserve nested list shape. Explicit target declarations remain authoritative. Record mapping still requires a declared record target. Ambiguous, no-width, partial-path, child-endpoint, compound-update, and VHDL surfaces remain unchanged, and incompatible later aggregate contracts fail closed.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `AGGREGATE-AUTOGROWTH-FROM-USAGE.5` | `pending` | The audit found one bounded proof source: direct RHS concat can build an ordered list contract from exact operand specs, while record mapping still requires a declared record target. |

## Audit Findings

- Direct `.fsm` already preserves aggregate contracts when the author declares
  a `+types` alias and attaches it through `+size`; typed member/item RHS
  paths, partial aggregate LHS writes, whole aggregate RHS shape checks, and
  RHS concat source-shape checks all depend on that explicit anchor.
- Direct `.fsm` aggregate constants and package aggregate values already infer
  canonical list/record payload shapes for scalar leaf access, whole-root
  packed literal lowering, and shape validation against declared aggregate
  targets.
- Before `AGGREGATE-AUTOGROWTH-FROM-USAGE.3`, direct `.fsm` whole aggregate
  constants assigned to an undeclared whole signal lowered to a packed vector
  only. A local probe with `(= (OUT> FRAME))` where `FRAME` is a record
  constant produced a width-only `output reg [4:0] OUT` declaration and lost
  the record field contract, even though the RHS payload was already
  unambiguous.
- Direct RHS concat expressions already infer ordered list/record source
  contracts when the target has a declared aggregate type. Inferring aggregate
  contracts from concat into an undeclared target is useful but is a separate
  source-position decision because it may depend on operand width evidence.
- The direct RHS concat audit found that only the list side is self-contained:
  `concat_expression_list_type_spec` already builds ordered scalar/list/record
  item specs from exact operands, including nested concat operands. Record
  mapping is target-aware because member names come from a declared record
  target, so anonymous record inference from concat alone remains out of scope.
- Composition already has a bounded aggregate top-port inference path:
  declared aggregate top-port paths, whole-root links to typed child inputs,
  and uniform unlinked same-name child inputs can seed aggregate root
  contracts. Child endpoint member/item access without a declared endpoint
  aggregate type still fails closed.
- ISF lowering emits scheduled `.fsm` with explicit storage/interface widths
  and declared aggregate aliases where the ISF surface owns them; broad
  aggregate autogrowth remains outside ISF lowering.
- Regression coverage exists for declared aggregate aliases, package/local
  aggregate values, partial aggregate LHS shape checks, concat/deconstruct
  aggregate source contracts, composition top-expression inference, expected
  failures for missing aggregate endpoint declarations, corpus accounting, and
  mdBook/live-doc truth checks.

## Completed Implementation Slice

`AGGREGATE-AUTOGROWTH-FROM-USAGE.3` implemented only direct whole-signal
LHS aggregate contract inference from a whole aggregate RHS constant root.

The proof source is the already-canonical aggregate payload for the RHS symbol.
The inferred target contract should be recorded on the target signal before
HDL planning so the existing SystemVerilog typedef path can preserve the
shape. The slice will not infer arbitrary member/index roots, will not infer
from child endpoints, will not change VHDL, will not change backend-owned
struct lowering policy, and will not treat width equality alone as aggregate
compatibility.

## Completed Follow-up Audit

`AGGREGATE-AUTOGROWTH-FROM-USAGE.4` audited direct RHS concat autogrowth
before implementation. Existing concat/deconstruct handling already builds
aggregate source contracts for declared aggregate targets. The safe
undeclared-target widening is list-only: the authored concat order provides
the list item order, nested concat operands preserve nested list shape, and
each operand must already have an exact scalar or aggregate type spec.

## Selected Next Slice

`AGGREGATE-AUTOGROWTH-FROM-USAGE.5` will implement direct RHS concat
autogrowth only for undeclared whole targets that can receive a generated list
contract. It will not infer anonymous record member names, will not change
explicit declarations, will not accept no-width operands, and will preserve
fail-closed aggregate-contract diagnostics for incompatible later assignments.

## Decisions

- `2026-05-24`: The first executable leaf is an audit/design slice, not an
  implementation slice. Aggregate growth touches shared typing and backend
  emission, so a behavior-bearing slice must first identify one narrow
  source position and preserve fail-closed diagnostics for ambiguous shape
  evidence.
- `2026-05-24`: The first implementation slice is direct whole-signal LHS
  aggregate contract inference from a whole aggregate RHS constant root. This
  source is selected because the RHS constant payload is already canonical,
  list/record shape is complete before assignment parsing finishes, and the
  target is a whole signal rather than a partial path.
- `2026-05-24`: Direct whole-signal aggregate targets now inherit a generated
  aggregate type contract from whole aggregate RHS constant roots only when
  the target has no explicit declaration. Explicit `+size` or aggregate type
  declarations remain authoritative, incompatible later aggregate constants
  fail closed against the inferred contract, and non-constant or ambiguous
  source positions remain unchanged.
- `2026-05-24`: The next frontier is an audit of direct RHS concat target
  autogrowth. Concat sources are useful but less canonical than constant
  roots, so they need a separate source-position review before code changes.
- `2026-05-24`: The direct RHS concat audit selected a list-only
  implementation frontier. Concat order is enough evidence for a list
  contract when every operand has an exact type spec; it is not enough
  evidence for anonymous record member names, so record mapping remains
  target-declared only.

## Open Questions

- Whether anonymous record contracts should ever be inferred from direct RHS
  concat without a declared record target remains out of scope.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `AGGREGATE-AUTOGROWTH-FROM-USAGE.1` | `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: Files=3, Tests=351` |
| `2026-05-24` | `AGGREGATE-AUTOGROWTH-FROM-USAGE.2` | `prove -Iperl t/276-direct-local-aggregate-values.t t/280-declarative-aggregate-types.t t/281-structural-declared-type-contracts.t t/285-aggregate-expression-type-support.t t/288-composition-aggregate-top-expression-inference.t t/248-regression-corpus-accounting.t`; `mdbook build docs/book`; `git diff --check` | `passed: Files=6, Tests=3085` |
| `2026-05-24` | `AGGREGATE-AUTOGROWTH-FROM-USAGE.3` | `perl -Iperl -c perl/FSM/Adapter/FSMGenFull/Parser.pm`; `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`; `perl -Iperl -c t/1321-direct-aggregate-autogrowth.t`; `prove -Iperl t/1321-direct-aggregate-autogrowth.t t/248-regression-corpus-accounting.t t/261-regression-corpus-supported-language-features.t`; `prove -Iperl t/296-regression-corpus-supported-behavior.t t/301-check-json-supported-corpus.t t/303-normalized-semantic-json-supported-corpus.t t/297-capability-manifest.t t/359-support-accounting-corpus-runtime-audit.t t/372-support-accounting-catalog-path-audit.t`; `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: direct/corpus Files=3, Tests=3085; supported-corpus gates Files=6, Tests=27; feature-backlog audit Files=1, Tests=15` |
| `2026-05-24` | `AGGREGATE-AUTOGROWTH-FROM-USAGE.4` | `prove -Iperl t/285-aggregate-expression-type-support.t t/270-systemverilog-assignment-width-contract-validation.t t/248-regression-corpus-accounting.t`; `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: focused concat/corpus Files=3, Tests=3088; feature-backlog audit Files=1, Tests=15` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `AGGREGATE-AUTOGROWTH-FROM-USAGE.1` | `b0f4783e AGGREGATE-AUTOGROWTH-FROM-USAGE.1: select aggregate autogrowth work` | `selection slice` |
| `AGGREGATE-AUTOGROWTH-FROM-USAGE.2` | `AGGREGATE-AUTOGROWTH-FROM-USAGE.2: audit aggregate autogrowth frontier` | `audit/design slice` |
| `AGGREGATE-AUTOGROWTH-FROM-USAGE.3` | `AGGREGATE-AUTOGROWTH-FROM-USAGE.3: infer aggregate constant targets` | `implementation slice` |
| `AGGREGATE-AUTOGROWTH-FROM-USAGE.4` | `AGGREGATE-AUTOGROWTH-FROM-USAGE.4: audit RHS concat autogrowth` | `audit/design slice` |
| `AGGREGATE-AUTOGROWTH-FROM-USAGE.5` | `pending` | `implementation slice` |

## Changelog

- `2026-05-24`: Created active task tree and selected the audit/design
  frontier.
- `2026-05-24`: Completed the audit/design frontier and selected direct
  whole-signal aggregate contract inference from whole aggregate RHS constants
  as the first implementation slice.
- `2026-05-24`: Completed direct whole-signal aggregate contract inference
  from whole aggregate RHS constants and selected direct RHS concat autogrowth
  audit as the next frontier.
- `2026-05-24`: Completed direct RHS concat autogrowth audit and selected a
  list-only implementation frontier for undeclared whole targets.
