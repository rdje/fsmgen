# ISF-PARAM-OVERRIDE-CONSTANTS: Actor Constants In Activation Parameters

## Metadata

- Tree ID: `ISF-PARAM-OVERRIDE-CONSTANTS`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Allow generated ISF activation parameter overrides to use actor-local constants
as static specialization values, without turning parameters into runtime
signals or requiring generated composition tops to resolve parent-local names.

## Non-Goals

- Do not accept actor parameters, transaction parameters, storage signals,
  interface ports, or transaction locals as parameter override values.
- Do not accept arbitrary parameter expressions in this tree.
- Do not widen direct `(on ...)` activation; it remains unsupported for
  activation-site `(params ...)`.
- Do not change reusable-library `use` parameter value semantics in this tree.
- Do not add new schedule-report keys unless implementation discovers a real
  downstream need.

## Acceptance Criteria

- The selected contract is documented before code changes.
- Spawn, parameterized blocking `do`, and parameterized rule-trigger
  activation parameter overrides may use actor-local constants by name.
- Actor constants are resolved to their literal values before generated-top
  emission, so generated `?fsmc` parameter overrides remain self-contained.
- Aggregate/list override leaves may use actor constants when the declared
  parameter shape matches.
- Unknown names, actor/transaction parameter names used as values, runtime
  signals, and expression values fail closed with targeted diagnostics.
- Focused regressions cover accepted spawn/`do`/rule-trigger constants and
  rejected unknown/runtime-symbol values.
- The mdBook, ISF spec, downstream handoff, public contract where warranted,
  task tree, roadmap, and live docs stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-PARAM-OVERRIDE-CONSTANTS`
  Status: `active`
  Goal: `Track actor-local constants as activation parameter override values.`
  Children: `ISF-PARAM-OVERRIDE-CONSTANTS.1`,
  `ISF-PARAM-OVERRIDE-CONSTANTS.2`

- ID: `ISF-PARAM-OVERRIDE-CONSTANTS.1`
  Status: `done`
  Goal: `Specify the actor-constant activation parameter contract.`
  Acceptance: `The task tree, ISF spec, and mdBook backlog define the future source shape, resolution point, diagnostics, and report/top-artifact impact before parser or scheduler changes.`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-PARAM-OVERRIDE-CONSTANTS.1: specify const params`

- ID: `ISF-PARAM-OVERRIDE-CONSTANTS.2`
  Status: `pending`
  Goal: `Implement actor-constant activation parameter overrides.`
  Acceptance: `Actor constants work as static activation parameter override values for spawn, generated blocking do, and rule-trigger sites; malformed or runtime-looking names fail closed; focused tests and synchronized docs pass.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-PARAM-OVERRIDE-CONSTANTS.2` | `pending` | The contract is selected; implementation is the next executable slice. |

## Decisions

- `2026-05-16`: The first symbolic parameter override value source is
  actor-local constants only. They are already compile-time non-negative
  literals, already emitted into scheduled `.fsm`, and already used by static
  wait counts.
- `2026-05-16`: Actor constants used in activation `(params ...)` are resolved
  to literal values inside the ISF lowerer before generated-top emission. The
  generated `?fsmc` parameter override therefore stays self-contained and does
  not depend on parent-local constant lookup in the composition layer.
- `2026-05-16`: Constant names may appear as scalar override values or as
  scalar leaves inside aggregate/list override values. Shape compatibility
  remains the existing scalar-vs-list shape rule.
- `2026-05-16`: Unknown scalar names remain fail-closed. Actor parameters,
  transaction parameters, runtime signals, interface ports, storage names, and
  expression/list operators are not static parameter value sources in this
  tree.
- `2026-05-16`: Existing report fields are expected to be sufficient:
  `generated_composition.instances[].parameter_bindings[]` can continue to
  report `source => override` and the resolved literal value. If implementation
  needs to preserve symbolic provenance as a new public field, that leaf must
  update the public contract, downstream handoff, manifest metadata, and tests
  in the same slice.

## Open Questions

- None for the selected first slice.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-PARAM-OVERRIDE-CONSTANTS.1` | `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-16` | `ISF-PARAM-OVERRIDE-CONSTANTS.2` | `pending` | `pending` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-PARAM-OVERRIDE-CONSTANTS.1` | `ISF-PARAM-OVERRIDE-CONSTANTS.1: specify const params` | Selected actor-local constants as the first symbolic activation parameter value source. |
| `ISF-PARAM-OVERRIDE-CONSTANTS.2` | `pending` | `pending` |

## Changelog

- `2026-05-16`: Created the task tree and completed
  `ISF-PARAM-OVERRIDE-CONSTANTS.1`; active frontier advances to
  `ISF-PARAM-OVERRIDE-CONSTANTS.2`.
