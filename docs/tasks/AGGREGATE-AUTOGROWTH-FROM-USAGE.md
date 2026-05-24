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
    `AGGREGATE-AUTOGROWTH-FROM-USAGE.3`

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
  Status: `pending`
  Goal: `Infer a direct whole-signal aggregate type contract from a whole aggregate RHS constant.`
  Acceptance: `When a direct .fsm whole-signal LHS has no declared aggregate type and is assigned a whole aggregate constant root whose payload already has one canonical list/record shape, FSMGen preserves that inferred contract on the target signal before HDL generation. Explicit target declarations remain authoritative, non-aggregate RHS expressions stay unchanged, arbitrary member/index autogrowth stays deferred, and incompatible later contracts still fail closed.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `AGGREGATE-AUTOGROWTH-FROM-USAGE.3` | `pending` | The audit found a fully bounded proof source: direct whole aggregate constants already carry a complete list/record payload shape, but assigning one to an undeclared whole signal currently preserves only packed width. |

## Audit Findings

- Direct `.fsm` already preserves aggregate contracts when the author declares
  a `+types` alias and attaches it through `+size`; typed member/item RHS
  paths, partial aggregate LHS writes, whole aggregate RHS shape checks, and
  RHS concat source-shape checks all depend on that explicit anchor.
- Direct `.fsm` aggregate constants and package aggregate values already infer
  canonical list/record payload shapes for scalar leaf access, whole-root
  packed literal lowering, and shape validation against declared aggregate
  targets.
- Direct `.fsm` whole aggregate constants assigned to an undeclared whole
  signal currently lower to a packed vector only. A local probe with
  `(OUT> = FRAME)` where `FRAME` is a record constant produced a width-only
  `output reg [4:0] OUT` declaration and lost the record field contract, even
  though the RHS payload was already unambiguous.
- Direct RHS concat expressions already infer ordered list/record source
  contracts when the target has a declared aggregate type. Inferring aggregate
  contracts from concat into an undeclared target is useful but is a separate
  source-position decision because it may depend on operand width evidence.
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

## Selected Next Slice

`AGGREGATE-AUTOGROWTH-FROM-USAGE.3` will implement only direct whole-signal
LHS aggregate contract inference from a whole aggregate RHS constant root.

The proof source is the already-canonical aggregate payload for the RHS symbol.
The inferred target contract should be recorded on the target signal before
HDL planning so the existing SystemVerilog typedef path can preserve the
shape. The slice will not infer arbitrary member/index roots, will not infer
from child endpoints, will not change VHDL, will not change backend-owned
struct lowering policy, and will not treat width equality alone as aggregate
compatibility.

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

## Open Questions

- Whether direct RHS concat should also grow undeclared whole-signal list
  contracts remains a later source-position decision after the aggregate
  constant-root slice ships or is rejected.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `AGGREGATE-AUTOGROWTH-FROM-USAGE.1` | `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: Files=3, Tests=351` |
| `2026-05-24` | `AGGREGATE-AUTOGROWTH-FROM-USAGE.2` | `prove -Iperl t/276-direct-local-aggregate-values.t t/280-declarative-aggregate-types.t t/281-structural-declared-type-contracts.t t/285-aggregate-expression-type-support.t t/288-composition-aggregate-top-expression-inference.t t/248-regression-corpus-accounting.t`; `mdbook build docs/book`; `git diff --check` | `passed: Files=6, Tests=3085` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `AGGREGATE-AUTOGROWTH-FROM-USAGE.1` | `b0f4783e AGGREGATE-AUTOGROWTH-FROM-USAGE.1: select aggregate autogrowth work` | `selection slice` |
| `AGGREGATE-AUTOGROWTH-FROM-USAGE.2` | `AGGREGATE-AUTOGROWTH-FROM-USAGE.2: audit aggregate autogrowth frontier` | `audit/design slice` |
| `AGGREGATE-AUTOGROWTH-FROM-USAGE.3` | `pending` | `implementation slice` |

## Changelog

- `2026-05-24`: Created active task tree and selected the audit/design
  frontier.
- `2026-05-24`: Completed the audit/design frontier and selected direct
  whole-signal aggregate contract inference from whole aggregate RHS constants
  as the first implementation slice.
