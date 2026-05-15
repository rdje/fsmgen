# ISF-ACTIVATION-PARAM-OVERRIDES: Remaining Activation Parameter Overrides

## Metadata

- Tree ID: `ISF-ACTIVATION-PARAM-OVERRIDES`
- Status: `done`
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
  Status: `done`
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
  Status: `done`
  Goal: `Implement rule-trigger parameter overrides.`
  Acceptance: `Rule actions may use the documented `(trigger transaction (params ...))` subset; accepted overrides specialize generated hardware rather than mutable runtime parameters; malformed overrides fail closed; existing rule-trigger input bindings still work; focused report and HDL-reaching tests pass.`
  Verification: `perl -Iperl -c` for changed parser/lowering/contract modules and new/updated tests; `prove -Iperl t/1248-isf-rule-trigger-parameter-binding.t t/1171-isf-rule-trigger-fanin.t t/1172-isf-rule-trigger-fanin-schedule-report.t t/1215-isf-spawn-parameter-binding.t t/1217-isf-generated-composition-schedule-report.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-ACTIVATION-PARAM-OVERRIDES.3: ship trigger params`

- ID: `ISF-ACTIVATION-PARAM-OVERRIDES.4`
  Status: `done`
  Goal: `Specify the direct transaction activation parameter boundary.`
  Acceptance: `The task tree, spec, and mdBook define whether direct `(on ...)` activation can legally carry static parameter overrides, what syntax is accepted or rejected, and how authors should model runtime-varying values.`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-ACTIVATION-PARAM-OVERRIDES.4: specify direct activation params`

- ID: `ISF-ACTIVATION-PARAM-OVERRIDES.5`
  Status: `done`
  Goal: `Implement or close the direct transaction activation parameter boundary.`
  Acceptance: `The implemented scheduler behavior, diagnostics, public docs, report contract, and tests match the decision from ISF-ACTIVATION-PARAM-OVERRIDES.4; unsupported direct activation parameter syntax is explicitly rejected rather than ignored.`
  Verification: `perl -Iperl -c t/1195-isf-sample-clause-boundary.t`; `prove -Iperl t/1195-isf-sample-clause-boundary.t t/1112-isf-public-interface-contract.t t/1144-isf-public-tested-by-metadata-audit.t`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-ACTIVATION-PARAM-OVERRIDES.5: close direct activation params`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | All known leaves in this task tree are complete. The next PNT selection should use the roadmap/task-tree frontier outside this tree. |

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
- `2026-05-16`: `ISF-ACTIVATION-PARAM-OVERRIDES.3` ships rule-trigger
  parameter overrides through generated child activation instances. Accepted
  parameterized rule triggers preserve existing per-rule trigger and input
  payload source timing, then route those sources through generated handoff DTs
  to the generated child instance.
- `2026-05-16`: Once a transaction target is generated, unparameterized rule
  triggers to that target lower through default-valued generated trigger
  instances rather than emitting a local fan-in to a skipped parent body.
- `2026-05-16`: The implementation leaf widens public syntax, generated
  composition reports, transaction port-binding report provenance, and tested
  public contract metadata. The public contract advertised
  [t/1248-isf-rule-trigger-parameter-binding.t](../../t/1248-isf-rule-trigger-parameter-binding.t)
  in `tested_by`.
- `2026-05-16`: Direct `(on ...)` activation is not an activation-site
  parameter override surface. It is the transaction's own entry guard, not a
  caller-owned generated instance, so `(on start (params ...))` must fail
  closed rather than specializing hardware or creating mutable runtime
  parameter signals. Runtime-varying entry values belong in transaction ports,
  `(sample ...)`, or supported activation-site `(bind ...)` payloads. Static
  specialization belongs on generated activation forms such as `spawn`,
  parameterized blocking `do`, and parameterized rule `trigger`.
- `2026-05-16`: The implementation/closure leaf keeps the existing fail-closed
  lowerer behavior for unsupported `(on ...)` body forms and adds focused
  coverage for `(on start (params ...))` through
  [t/1195-isf-sample-clause-boundary.t](../../t/1195-isf-sample-clause-boundary.t).
  No scheduler, report, or manifest shape change is required.

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

`ISF-ACTIVATION-PARAM-OVERRIDES.5` should cover at least:

- Direct `(on start (params ...))` fails before scheduled artifacts with the
  existing direct-entry body diagnostic or a sharper equivalent.
- Legal `(on start (sample ...))` behavior remains unchanged.
- Transaction-local `params` continue to work as definition defaults only for
  generated transaction instances; a non-generated direct transaction still
  rejects parameter declarations under the existing generated-child boundary.
- Docs, schedule-report/public-contract text, and tests all match the
  fail-closed direct-activation decision from this specification leaf.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-ACTIVATION-PARAM-OVERRIDES.1` | `git diff --check` | `passed` |
| `2026-05-16` | `ISF-ACTIVATION-PARAM-OVERRIDES.2` | `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-16` | `ISF-ACTIVATION-PARAM-OVERRIDES.3` | `perl -Iperl -c` for changed parser/lowering/contract modules and new/updated tests; focused trigger/composition/public-contract `prove` set; broader `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-16` | `ISF-ACTIVATION-PARAM-OVERRIDES.4` | `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-16` | `ISF-ACTIVATION-PARAM-OVERRIDES.5` | `perl -Iperl -c t/1195-isf-sample-clause-boundary.t`; `prove -Iperl t/1195-isf-sample-clause-boundary.t t/1112-isf-public-interface-contract.t t/1144-isf-public-tested-by-metadata-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-ACTIVATION-PARAM-OVERRIDES.1` | `ISF-ACTIVATION-PARAM-OVERRIDES.1: open activation params tree` | Tree-opening slice; no compiler behavior change. |
| `ISF-ACTIVATION-PARAM-OVERRIDES.2` | `ISF-ACTIVATION-PARAM-OVERRIDES.2: specify trigger params` | Selected generated child activation as the rule-trigger parameter override contract; implementation remains pending. |
| `ISF-ACTIVATION-PARAM-OVERRIDES.3` | `ISF-ACTIVATION-PARAM-OVERRIDES.3: ship trigger params` | Shipped generated-child rule-trigger parameter overrides; direct activation remains pending. |
| `ISF-ACTIVATION-PARAM-OVERRIDES.4` | `ISF-ACTIVATION-PARAM-OVERRIDES.4: specify direct activation params` | Selected a fail-closed boundary for direct `(on ...)` activation parameters. |
| `ISF-ACTIVATION-PARAM-OVERRIDES.5` | `ISF-ACTIVATION-PARAM-OVERRIDES.5: close direct activation params` | Added focused fail-closed coverage and closed the tree. |

## Changelog

- `2026-05-16`: Created the active R14 task tree and completed
  `ISF-ACTIVATION-PARAM-OVERRIDES.1` as the tree-opening slice. The active
  frontier is now `ISF-ACTIVATION-PARAM-OVERRIDES.2`.
- `2026-05-16`: Completed `ISF-ACTIVATION-PARAM-OVERRIDES.2`; the active
  frontier advances to `ISF-ACTIVATION-PARAM-OVERRIDES.3`.
- `2026-05-16`: Completed `ISF-ACTIVATION-PARAM-OVERRIDES.3`; the active
  frontier advances to `ISF-ACTIVATION-PARAM-OVERRIDES.4`.
- `2026-05-16`: Completed `ISF-ACTIVATION-PARAM-OVERRIDES.4`; the active
  frontier advances to `ISF-ACTIVATION-PARAM-OVERRIDES.5`.
- `2026-05-16`: Completed `ISF-ACTIVATION-PARAM-OVERRIDES.5`; the task tree
  is closed.
