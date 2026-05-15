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
  Commit: `pending`

- ID: `ISF-ACTIVATION-PARAM-OVERRIDES.2`
  Status: `pending`
  Goal: `Specify the rule-trigger parameter override lowering contract.`
  Acceptance: `The task tree, spec, and mdBook state the exact source shape, specialization strategy, diagnostics, schedule-report/public-surface impact, and focused test plan for parameterized rule triggers before scheduler code changes.`
  Verification: `pending`
  Commit: `pending`

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
| 1 | `ISF-ACTIVATION-PARAM-OVERRIDES.2` | `pending` | Rule-trigger parameter overrides are the next backlog item called out by the roadmap, and their lowering strategy must be fixed before scheduler edits. |

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

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-ACTIVATION-PARAM-OVERRIDES.1` | `ISF-ACTIVATION-PARAM-OVERRIDES.1: open activation params tree` | Tree-opening slice; no compiler behavior change. |
| `ISF-ACTIVATION-PARAM-OVERRIDES.2` | `pending` | Pending. |
| `ISF-ACTIVATION-PARAM-OVERRIDES.3` | `pending` | Pending. |
| `ISF-ACTIVATION-PARAM-OVERRIDES.4` | `pending` | Pending. |
| `ISF-ACTIVATION-PARAM-OVERRIDES.5` | `pending` | Pending. |

## Changelog

- `2026-05-16`: Created the active R14 task tree and completed
  `ISF-ACTIVATION-PARAM-OVERRIDES.1` as the tree-opening slice. The active
  frontier is now `ISF-ACTIVATION-PARAM-OVERRIDES.2`.
