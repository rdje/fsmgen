# ISF-ACTIVATION-PARAM-OVERRIDES: Remaining Activation Parameter Overrides

## Metadata

- Tree ID: `ISF-ACTIVATION-PARAM-OVERRIDES`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Ship the remaining activation-site transaction parameter override semantics
that were deliberately left out of the closed
`ISF-TRANSACTION-ACTIVATION` tree: rule-trigger parameter overrides and the
direct transaction activation boundary.

## Non-Goals

- Do not reinterpret static transaction parameters as runtime payload signals.
- Do not silently share one scheduled transaction body across activation sites
  with different parameter values.
- Do not widen the value domain beyond the currently shipped scalar and
  compatible aggregate/list literal override forms without a separate leaf.
- Do not change expression-valued activation port binding semantics except
  where a leaf explicitly needs to preserve existing binding behavior beside
  parameter overrides.
- Do not infer multi-clock or CDC behavior from activation parameter syntax.

## Acceptance Criteria

- Rule-trigger parameter override behavior is specified, implemented, reported,
  documented in the mdBook and spec, and validated through focused tests.
- Direct transaction activation parameter behavior is specified precisely as
  shipped or fail-closed, with diagnostics and documentation that prevent
  authors from assuming unsupported syntax works.
- Schedule-report and public-contract surfaces are synchronized if new bounded
  public keys or tested guidance are introduced.
- The task tree, roadmap status, live recovery docs, and change history stay
  current after each leaf.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-ACTIVATION-PARAM-OVERRIDES`
  Status: `active`
  Goal: `Track and ship the remaining activation-site parameter override work.`
  Children: `ISF-ACTIVATION-PARAM-OVERRIDES.1`,
  `ISF-ACTIVATION-PARAM-OVERRIDES.2`,
  `ISF-ACTIVATION-PARAM-OVERRIDES.3`,
  `ISF-ACTIVATION-PARAM-OVERRIDES.4`,
  `ISF-ACTIVATION-PARAM-OVERRIDES.5`

- ID: `ISF-ACTIVATION-PARAM-OVERRIDES.1`
  Status: `done`
  Goal: `Attach the remaining activation parameter work to an active R14 task tree.`
  Acceptance: `Task-tree index, roadmap status, README index, live recovery docs, and change history name this tree as the active owner for rule-trigger and direct-activation parameter overrides, with no compiler behavior change.`
  Verification: `git diff --check`
  Commit: `ISF-ACTIVATION-PARAM-OVERRIDES.1: open activation params tree`

- ID: `ISF-ACTIVATION-PARAM-OVERRIDES.2`
  Status: `done`
  Goal: `Specify the rule-trigger parameter override lowering contract.`
  Acceptance: `The task tree, spec, and mdBook state the exact source shape, specialization strategy, diagnostics, schedule-report/public-surface impact, and focused test plan for parameterized rule triggers before scheduler code changes.`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-ACTIVATION-PARAM-OVERRIDES.2: specify trigger params`

- ID: `ISF-ACTIVATION-PARAM-OVERRIDES.3`
  Status: `pending`
  Goal: `Implement rule-trigger parameter overrides.`
  Acceptance: `Rule actions may use the documented `(trigger transaction (params ...))` subset; accepted overrides specialize generated hardware rather than mutable runtime parameters; malformed overrides fail closed; existing rule-trigger input bindings still work; focused report and HDL-reaching tests pass.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-ACTIVATION-PARAM-OVERRIDES.4`
  Status: `pending`
  Goal: `Specify the direct transaction activation parameter boundary.`
  Acceptance: `The task tree, spec, and mdBook define whether direct `(on ...)` activation can legally carry static parameter overrides, what syntax is accepted or rejected, and how authors should model runtime-varying values.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-ACTIVATION-PARAM-OVERRIDES.5`
  Status: `pending`
  Goal: `Implement or close the direct transaction activation parameter boundary.`
  Acceptance: `The implemented scheduler behavior, diagnostics, public docs, report contract, and tests match the decision from ISF-ACTIVATION-PARAM-OVERRIDES.4; unsupported direct activation parameter syntax is explicitly rejected rather than ignored.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-ACTIVATION-PARAM-OVERRIDES.3` | `pending` | The rule-trigger source shape, specialization strategy, diagnostics, report impact, and focused test plan are now specified; implementation is the next executable leaf. |

## Decisions

- `2026-05-16`: This tree owns only the activation parameter override work
  left after `ISF-TRANSACTION-ACTIVATION`: rule-trigger overrides and the
  direct transaction activation boundary.
- `2026-05-16`: Reuse the existing explicit `(params (NAME value) ...)`
  source shape wherever an activation form supports static specialization.
- `2026-05-16`: Treat parameter overrides as elaboration-time specialization
  values. Runtime-varying data must continue to use transaction ports and
  `(bind ...)` activation payloads.
- `2026-05-16`: Inspect the reusable ISF public synchronization checklist for
  every implementation leaf. The expected public scope includes syntax/spec
  docs, mdBook behavior, schedule-report metadata if new activation instances
  are reported, and focused public-contract/audit updates only when bounded
  public surfaces change.
- `2026-05-16`: `ISF-ACTIVATION-PARAM-OVERRIDES.2` selects generated child
  activation as the rule-trigger parameter override strategy. The source shape
  is `(trigger transaction (params (NAME value) ...) (bind ...))`; the
  implementation leaf must elaborate one static generated child activation
  instance per lexical parameterized trigger site, with deterministic names
  `{rule}_{transaction}_trigger_{ordinal}`.
- `2026-05-16`: The rule-trigger implementation must preserve the shipped
  trigger timing: rule DTs still emit one-cycle trigger sources and input
  payload sources, and generated handoff DTs route those sources to the
  generated instance start and input handoff ports.
- `2026-05-16`: Rule-trigger output bindings remain unsupported for the
  parameterized path because a rule does not wait for transaction completion.
  The generated child `done` handoff is still wired and reported for uniform
  generated composition.
- `2026-05-16`: The public sync scope for `.2` is documentation-only: spec,
  mdBook, task tree, roadmap, and live docs. Public contract code and manifest
  metadata remain unchanged until implementation introduces or changes bounded
  report keys or tested guidance.

## Focused Test Plan

`ISF-ACTIVATION-PARAM-OVERRIDES.3` should cover at least:

- Accepted parameterized rule trigger with one override, one input binding,
  generated child `.fsm`, generated top `?fsmc` params, and HDL reach.
- Multiple parameterized trigger sites to the same transaction with distinct
  deterministic instances and no mutable shared parameter signal.
- Mixed trigger sites when one target is generated: unparameterized trigger
  sites must either lower through default-valued generated instances or fail
  closed with a source-local diagnostic; they must not target a skipped local
  transaction body.
- Rule-trigger input binding timing remains source/payload based, and output
  bindings remain rejected.
- Malformed trigger params fail before scheduled artifacts: duplicate `params`
  blocks, malformed entries, duplicate override names, unknown parameters,
  incompatible aggregate/list values, unsupported symbolic/expression values,
  and generated handoff-name collisions.
- Schedule JSON exposes generated-composition instance metadata with
  `activation_kind => trigger` and parameter binding provenance, or the
  implementation leaf records why an existing bounded report field already
  covers it without widening the public contract.

## Open Questions

- The exact direct activation source surface is still unsettled. It does not
  block rule-trigger specification because `(on ...)` has no activation-site
  list shape equivalent to `do`, `spawn`, or rule action clauses today.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-ACTIVATION-PARAM-OVERRIDES.1` | `git diff --check` | `passed` |
| `2026-05-16` | `ISF-ACTIVATION-PARAM-OVERRIDES.2` | `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-ACTIVATION-PARAM-OVERRIDES.1` | `ISF-ACTIVATION-PARAM-OVERRIDES.1: open activation params tree` | Tree-opening slice; no compiler behavior change. |
| `ISF-ACTIVATION-PARAM-OVERRIDES.2` | `ISF-ACTIVATION-PARAM-OVERRIDES.2: specify trigger params` | Selected generated child activation as the rule-trigger parameter override contract; implementation remains pending. |
| `ISF-ACTIVATION-PARAM-OVERRIDES.3` | `pending` | Pending. |
| `ISF-ACTIVATION-PARAM-OVERRIDES.4` | `pending` | Pending. |
| `ISF-ACTIVATION-PARAM-OVERRIDES.5` | `pending` | Pending. |

## Changelog

- `2026-05-16`: Created the active R14 task tree and completed
  `ISF-ACTIVATION-PARAM-OVERRIDES.1` as the tree-opening slice. The active
  frontier is now `ISF-ACTIVATION-PARAM-OVERRIDES.2`.
- `2026-05-16`: Completed `ISF-ACTIVATION-PARAM-OVERRIDES.2`; the active
  frontier advances to `ISF-ACTIVATION-PARAM-OVERRIDES.3`.
