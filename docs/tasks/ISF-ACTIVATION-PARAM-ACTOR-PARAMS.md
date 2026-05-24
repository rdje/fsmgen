# ISF-ACTIVATION-PARAM-ACTOR-PARAMS: Actor Parameters In Activation Overrides

## Metadata

- Tree ID: `ISF-ACTIVATION-PARAM-ACTOR-PARAMS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Allow generated ISF activation parameter overrides to use actor-local scalar
parameter defaults as static specialization values, matching the existing
compile-time actor-constant and enum-member override model.

## Non-Goals

- Do not accept transaction parameters as activation override values.
- Do not accept runtime interface/storage/transaction signals as activation
  override values.
- Do not accept arbitrary override expressions.
- Do not accept non-scalar actor parameters as activation override values.
  Aggregate/list override values may use actor-local scalar parameters as
  leaves only through the selected implementation leaf.
- Do not change direct `(on ...)` activation; it still has no parameter
  override source shape.
- Do not change reusable-library use-site parameter override semantics in this
  tree.

## Acceptance Criteria

- The selected contract is documented before implementation.
- Spawn, generated blocking `do`, and rule-trigger `(params ...)` overrides
  may use actor-local scalar parameter defaults by name.
- Actor parameter values are resolved to literal values before lowerer IR,
  schedule reports, and generated-top `?fsmc` emission.
- Scalar leaves inside compatible aggregate/list activation override values
  may use actor-local scalar parameter defaults.
- Unknown names, transaction parameters, runtime signals, arbitrary
  expressions, and non-scalar actor parameters fail closed with targeted
  diagnostics.
- The mdBook, ISF spec, downstream handoff, public contract, task tree,
  roadmap, and live docs stay synchronized when behavior ships.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-ACTIVATION-PARAM-ACTOR-PARAMS`
  Status: `done`
  Goal: `Track actor-local scalar parameter defaults as activation parameter override values`
  Children: `ISF-ACTIVATION-PARAM-ACTOR-PARAMS.1`,
  `ISF-ACTIVATION-PARAM-ACTOR-PARAMS.2`

- ID: `ISF-ACTIVATION-PARAM-ACTOR-PARAMS.1`
  Status: `done`
  Goal: `Select the actor-parameter activation override contract`
  Acceptance: `The task tree and live docs state the selected source shape, resolution point, diagnostics, non-goals, and next implementation leaf before code changes.`
  Verification: `passed`
  Commit: `ISF-ACTIVATION-PARAM-ACTOR-PARAMS.1: select actor param overrides`

- ID: `ISF-ACTIVATION-PARAM-ACTOR-PARAMS.2`
  Status: `done`
  Goal: `Implement actor-local scalar parameter defaults as activation override values`
  Acceptance: `Actor-local scalar parameter defaults work as static activation parameter override values for spawn, generated blocking do, and rule-trigger sites; malformed or runtime-looking names fail closed; focused tests and synchronized public docs pass.`
  Verification: `passed`
  Commit: `ISF-ACTIVATION-PARAM-ACTOR-PARAMS.2: ship actor param overrides`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | All planned leaves are complete. |

## Decisions

- `2026-05-24`: The first widening is actor-local scalar parameter defaults
  only. They are already compile-time defaults, already preserved in
  scheduled `.fsm` `+params`, and already accepted in positive static
  count/width contexts.
- `2026-05-24`: Actor parameter override values will resolve before generated
  activation metadata is published, the same as actor constants and enum
  members. Generated-top `?fsmc` parameter blocks and schedule reports remain
  self-contained literal views.
- `2026-05-24`: Non-scalar actor parameters remain rejected as scalar
  override values. Aggregate/list override values may use actor scalar
  parameters as leaves only when the implementation leaf explicitly proves
  the existing shape compatibility path preserves the same safety boundary.

## Open Questions

- None for the selected first implementation leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `ISF-ACTIVATION-PARAM-ACTOR-PARAMS.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-24` | `ISF-ACTIVATION-PARAM-ACTOR-PARAMS.2` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1249-isf-activation-parameter-constants.t`; `prove -Iperl t/1249-isf-activation-parameter-constants.t t/1215-isf-spawn-parameter-binding.t t/1248-isf-rule-trigger-parameter-binding.t`; `prove -Iperl t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t t/1256-feature-backlog-status-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-ACTIVATION-PARAM-ACTOR-PARAMS.1` | `ISF-ACTIVATION-PARAM-ACTOR-PARAMS.1: select actor param overrides` | `contract-selection slice` |
| `ISF-ACTIVATION-PARAM-ACTOR-PARAMS.2` | `ISF-ACTIVATION-PARAM-ACTOR-PARAMS.2: ship actor param overrides` | `implementation slice` |

## Changelog

- `2026-05-24`: Created task tree and selected the actor-local scalar
  parameter activation override contract.
- `2026-05-24`: Completed the selection leaf and advanced the frontier to
  `ISF-ACTIVATION-PARAM-ACTOR-PARAMS.2`.
- `2026-05-24`: Completed the implementation leaf and closed the task tree.
  Generated activation `(params ...)` override values now accept actor-local
  scalar parameter defaults for spawn, generated blocking `do`, rule-trigger
  sites, and scalar leaves inside compatible aggregate/list override values.
