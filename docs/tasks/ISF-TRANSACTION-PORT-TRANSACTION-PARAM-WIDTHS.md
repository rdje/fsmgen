# ISF-TRANSACTION-PORT-TRANSACTION-PARAM-WIDTHS: Transaction Parameter Transaction-Port Widths

## Metadata

- Tree ID: `ISF-TRANSACTION-PORT-TRANSACTION-PARAM-WIDTHS`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Allow same-transaction scalar parameter defaults to act as static width
evidence for transaction-local `(ports ...)` declarations when the resolved
default is a positive integer.

## Non-Goals

- Do not accept runtime signals, arbitrary expressions, aggregate/list
  transaction parameters, or zero-valued transaction parameters as port widths.
- Do not specialize transaction port widths through activation-site parameter
  overrides, generated child variants, or generated-top respecialization.
- Do not change transaction port binding timing, generated-top handoff naming,
  schedule-report key families, or HDL projection semantics beyond resolved
  positive integer widths.
- Do not widen actor interface, actor storage, bank depth, data-operation
  width, latency, watchdog, wait, repeat, or temporal-contract value domains
  in this tree.

## Acceptance Criteria

- Generated child transactions can use same-transaction scalar parameter
  defaults in `(input NAME (width TX_PARAM))` and
  `(output NAME (width TX_PARAM))` declarations when the default resolves to a
  positive integer.
- Direct/non-generated transactions can use their own scalar parameters for the
  same transaction-port width surface only after the direct validation gate is
  deliberately widened.
- Transaction-local names resolve before actor constants and actor parameters
  inside this transaction-port width value-domain slot.
- Zero, aggregate/list, forward, self/cyclic, runtime, expression, unknown,
  and cross-transaction parameter uses fail closed with targeted diagnostics
  or stay explicitly documented as deferred.
- Focused tests cover accepted generated-child and direct behavior plus
  rejected boundaries.
- `docs/ISF_SPEC.md`, `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md`,
  `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md`, the mdBook, README index, roadmap,
  task tree, `MEMORY.md`, `CHANGES.md`, `DEVELOPMENT_NOTES.md`, and
  `LIVE_ACHIEVEMENT_STATUS.md` stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-TRANSACTION-PORT-TRANSACTION-PARAM-WIDTHS`
  Status: `active`
  Goal: `Ship bounded transaction-parameter transaction-port width evidence.`
  Children: `ISF-TRANSACTION-PORT-TRANSACTION-PARAM-WIDTHS.1`,
  `ISF-TRANSACTION-PORT-TRANSACTION-PARAM-WIDTHS.2`,
  `ISF-TRANSACTION-PORT-TRANSACTION-PARAM-WIDTHS.3`

- ID: `ISF-TRANSACTION-PORT-TRANSACTION-PARAM-WIDTHS.1`
  Status: `done`
  Goal: `Select the bounded transaction-parameter transaction-port width tree
  before source/test changes.`
  Acceptance: `The task tree, active frontier, roadmap status, README index,
  mdBook backlog, and live docs identify this tree and the next implementation
  leaf without changing parser, scheduler, generated artifacts, public API, or
  runtime behavior.`
  Verification: `feature-backlog/live-book/book matrix audits; mdBook build;
  git diff check`
  Commit: `ab4537a4 ISF-TRANSACTION-PORT-TRANSACTION-PARAM-WIDTHS.1: select transaction port params`

- ID: `ISF-TRANSACTION-PORT-TRANSACTION-PARAM-WIDTHS.2`
  Status: `done`
  Goal: `Accept generated child same-transaction scalar parameter defaults as
  transaction-port width evidence.`
  Acceptance: `Generated child transactions accept positive resolved
  transaction parameters in transaction-local input/output port width options,
  publish resolved integer widths through parser handoff, scheduled .fsm,
  activation handoff storage, schedule reports, and HDL, and keep unsupported
  transaction parameter values fail-closed.`
  Verification: `syntax checks; focused transaction-port/public/spec/book tests; ISF no-book regression; live-doc/book audits; mdBook build; git diff check`
  Commit: `pending this commit`

- ID: `ISF-TRANSACTION-PORT-TRANSACTION-PARAM-WIDTHS.3`
  Status: `pending`
  Goal: `Accept direct same-transaction scalar parameter defaults as
  transaction-port width evidence.`
  Acceptance: `Direct transactions with params clauses are accepted only when
  at least one same-transaction transaction-port width option references a
  declared parameter, and unrelated direct transaction parameters remain
  fail-closed.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-TRANSACTION-PORT-TRANSACTION-PARAM-WIDTHS.3` | `pending` | `Generated child transaction-port parameter widths are implemented; direct/non-generated transaction validation is the remaining bounded widening.` |

## Decisions

- `2026-05-25`: Select transaction-local port widths as the next R14 feature
  because actor-parameter, actor-constant, and package-constant port widths
  are shipped, and same-transaction scalar parameters are now proven as static
  width evidence for data operations.
- `2026-05-25`: Split generated-child and direct/non-generated validation
  leaves. Generated child transaction params already have an accepted
  publication path, while direct transaction params need an explicit use gate
  so unrelated direct `(params ...)` clauses stay fail-closed.
- `2026-05-25`: Keep activation-site overrides out of scope. The accepted
  width is the transaction definition default; per-activation width
  specialization would require generated child variants or generated-top
  respecialization.
- `2026-05-25`: Implement the generated-child leaf at parser width-normalization
  time and keep the direct transaction gate closed. The parser resolves
  generated child `TX_PARAM` widths to positive integers before handoff, while
  direct/non-generated transaction-parameter port widths still fail closed
  until the direct validation leaf deliberately widens that surface.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ISF-TRANSACTION-PORT-TRANSACTION-PARAM-WIDTHS.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t` | `passed: Files=3, Tests=364` |
| `2026-05-25` | `ISF-TRANSACTION-PORT-TRANSACTION-PARAM-WIDTHS.1` | `mdbook build docs/book` | `passed` |
| `2026-05-25` | `ISF-TRANSACTION-PORT-TRANSACTION-PARAM-WIDTHS.1` | `git diff --check` | `passed` |
| `2026-05-25` | `ISF-TRANSACTION-PORT-TRANSACTION-PARAM-WIDTHS.2` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm perl/FSM/Support/ISFPublicInterfaceContract.pm t/1368-isf-transaction-port-transaction-param-widths.t t/1240-isf-transaction-port-declarations.t t/1336-isf-transaction-port-actor-param-widths.t t/1342-isf-transaction-port-actor-constant-widths.t t/1357-isf-transaction-port-package-constant-widths.t` | `passed` |
| `2026-05-25` | `ISF-TRANSACTION-PORT-TRANSACTION-PARAM-WIDTHS.2` | `prove -Iperl t/1368-isf-transaction-port-transaction-param-widths.t t/1240-isf-transaction-port-declarations.t t/1241-isf-transaction-port-bindings.t t/1243-isf-port-binding-schedule-report.t t/1336-isf-transaction-port-actor-param-widths.t t/1342-isf-transaction-port-actor-constant-widths.t t/1357-isf-transaction-port-package-constant-widths.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t` | `passed: Files=13, Tests=382` |
| `2026-05-25` | `ISF-TRANSACTION-PORT-TRANSACTION-PARAM-WIDTHS.2` | `./bin/ci-regression isf --no-book` | `passed: Files=274, Tests=1738` |
| `2026-05-25` | `ISF-TRANSACTION-PORT-TRANSACTION-PARAM-WIDTHS.2` | `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t` | `passed: Files=3, Tests=364` |
| `2026-05-25` | `ISF-TRANSACTION-PORT-TRANSACTION-PARAM-WIDTHS.2` | `mdbook build docs/book` | `passed` |
| `2026-05-25` | `ISF-TRANSACTION-PORT-TRANSACTION-PARAM-WIDTHS.2` | `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-TRANSACTION-PORT-TRANSACTION-PARAM-WIDTHS.1` | `ab4537a4 ISF-TRANSACTION-PORT-TRANSACTION-PARAM-WIDTHS.1: select transaction port params` | `selection slice` |
| `ISF-TRANSACTION-PORT-TRANSACTION-PARAM-WIDTHS.2` | `pending this commit` | `generated-child implementation slice` |
| `ISF-TRANSACTION-PORT-TRANSACTION-PARAM-WIDTHS.3` | `pending` | `direct/non-generated implementation slice` |

## Changelog

- `2026-05-25`: Created and activated the task tree for bounded
  same-transaction scalar parameter defaults in transaction-local port widths.
- `2026-05-25`: Closed selection validation with feature-backlog/live-book
  audits and mdBook build passing.
- `2026-05-25`: Implemented generated child same-transaction scalar parameter
  defaults as transaction-local port width evidence. Direct/non-generated
  transaction parameter port widths remain deferred for `.3`.
