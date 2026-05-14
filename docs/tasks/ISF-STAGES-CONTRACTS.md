# ISF-STAGES-CONTRACTS: Transaction Stage And Temporal Contract Lowering

## Metadata

- Tree ID: `ISF-STAGES-CONTRACTS`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-14`
- Last updated: `2026-05-14`
- Owner: repo-local workflow

## Goal

Turn parsed transaction `(stage ...)` and `(contract ...)` clauses from
fail-closed metadata into documented, scheduled, testable behavior for the
covered stage and temporal-check domains.

## Non-Goals

- Do not define an unbounded temporal logic language.
- Do not make legacy `(handshake ...)` metadata semantic in this tree; that
  decision belongs to `ISF-COMPATIBILITY`.
- Do not bypass the reviewable scheduled `.fsm` artifact.

## Acceptance Criteria

- Current stage/contract parsing, preservation, and fail-closed lowering are
  inventoried.
- A first bounded stage model is specified, including valid/ready interaction
  if covered.
- A first bounded temporal contract model is specified, including generated
  check representation or explicit deferred subfamilies.
- Lowering emits reviewable scheduled artifacts and generated HDL/checks for
  the covered cases.
- Unsupported stage/contract shapes fail with targeted diagnostics.
- Schedule-report metadata, tests, ISF spec, public contract, mdBook, roadmap,
  and live docs agree.

## Task Tree

- ID: `ISF-STAGES-CONTRACTS`
  Status: `active`
  Goal: `Ship bounded transaction stage and temporal contract lowering.`
  Children: `ISF-STAGES-CONTRACTS.1`, `ISF-STAGES-CONTRACTS.2`,
  `ISF-STAGES-CONTRACTS.3`, `ISF-STAGES-CONTRACTS.4`,
  `ISF-STAGES-CONTRACTS.5`, `ISF-STAGES-CONTRACTS.6`

- ID: `ISF-STAGES-CONTRACTS.1`
  Status: `done`
  Goal: `Inventory current stage/contract parse and fail-closed behavior.`
  Acceptance: `The task file lists accepted parsed forms, preservation points,
  current diagnostics, and the exact missing lowering hooks.`
  Verification: `prove -l t/1175-isf-contract-fail-closed.t t/1179-isf-phase-stage-boundary.t t/1180-isf-unsupported-transaction-clause-boundary.t`;
  `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-STAGES-CONTRACTS.1: inventory stage contract boundary`

- ID: `ISF-STAGES-CONTRACTS.2`
  Status: `done`
  Goal: `Specify first bounded transaction stage semantics.`
  Acceptance: `The tree records supported stage syntax, generated state/handshake
  behavior, ordering guarantees, and rejected stage shapes.`
  Verification: `prove -l t/1179-isf-phase-stage-boundary.t t/1180-isf-unsupported-transaction-clause-boundary.t`;
  `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-STAGES-CONTRACTS.2: specify bounded stage semantics`

- ID: `ISF-STAGES-CONTRACTS.3`
  Status: `pending`
  Goal: `Specify first bounded temporal contract semantics.`
  Acceptance: `The tree records supported temporal assertions/checks,
  generated artifact shape, reset behavior, report metadata, and rejected
  contract forms.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-STAGES-CONTRACTS.4`
  Status: `pending`
  Goal: `Implement stage lowering.`
  Acceptance: `Covered stage forms lower into scheduled FSM, parse through
  the normal frontend, and generate HDL/check artifacts as specified.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-STAGES-CONTRACTS.5`
  Status: `pending`
  Goal: `Implement temporal contract lowering.`
  Acceptance: `Covered contract forms lower into generated checks or scheduled
  artifacts, while unsupported forms fail closed with targeted diagnostics.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-STAGES-CONTRACTS.6`
  Status: `pending`
  Goal: `Add reports, tests, and synchronized docs.`
  Acceptance: `Schedule reports, regressions, ISF spec, public contract,
  mdBook, and live docs describe the shipped stage/contract behavior.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-STAGES-CONTRACTS.3` | `pending` | Temporal contract semantics must be bounded before the contract lowering path is implemented. |

## ISF-STAGES-CONTRACTS.1 Inventory

Current implementation points:

- Parser owner: `perl/FSM/Adapter/ISF/Parser.pm`.
- Lowering owner: `perl/FSM/Scheduler/ISF/LoweringIR.pm`.
- Schedule JSON owner: `perl/FSM/Scheduler/ISF/Emitter/JSON.pm`.
- Regression anchors: `t/1175-isf-contract-fail-closed.t`,
  `t/1179-isf-phase-stage-boundary.t`, and
  `t/1180-isf-unsupported-transaction-clause-boundary.t`.

Accepted parsed forms today:

- Actor-level `(phase name property...)` is accepted when `name` is a
  non-empty scalar and every property is a non-empty list form with a scalar
  head. Duplicate actor phase names fail before actor-shell return.
- Actor-level `(stage name property...)` uses the same named-body parser
  boundary as actor phases. It is accepted as metadata only; duplicate actor
  stage names fail before actor-shell return.
- Transaction-level `(phase name property...)` uses the same structural
  parser boundary and remains accepted in transaction bodies. It lowers as a
  pass-through sequential state marker.
- Transaction-level `(stage name property...)` uses the same structural parser
  boundary, including inside nested `when`, `switch`, and `repeat` bodies, but
  it is not lowered yet.
- Transaction-level `(contract payload...)` is accepted by the raw Lispish
  parser and carried as a transaction clause, including inside nested `when`,
  `switch`, and `repeat` bodies. It has no structural payload validation yet
  beyond list-form transaction-clause handling.

Preservation points:

- Actor phases are preserved as `$actor->{phases}` entries with `{ name, body }`.
- Actor stages are preserved as `$actor->{stages}` entries with `{ name, body }`.
- Transaction phases, stages, and contracts remain in each transaction's
  `clauses` array until the scheduler validates supported transaction clauses.
- Actor-level phase/stage metadata is not copied into `LoweringIR`, schedule
  JSON, generated `.fsm`, generated composition tops, or HDL today.
- Transaction contract clauses are not copied into `LoweringIR`, schedule JSON,
  generated `.fsm`, generated checks, or HDL today.
- Transaction stage clauses are not copied into `LoweringIR`, schedule JSON,
  generated `.fsm`, generated pipeline state, generated checks, or HDL today.
- Transaction phase clauses do reach `LoweringIR` as states named
  `<transaction>_phase_<index>` with `kind => sequential`, no assignments, and
  the usual fall-through transition.

Current diagnostics:

- Malformed actor/transaction phase or stage names fail with
  `Error: (phase ...) requires a scalar name` or
  `Error: (stage ...) requires a scalar name`.
- Malformed phase/stage body entries fail with
  `Error: phase '<name>' body entries must be list forms` or
  `Error: stage '<name>' body entries must be list forms`.
- Duplicate actor phases/stages fail with
  `Error: duplicate actor phase '<name>'` or
  `Error: duplicate actor stage '<name>'`.
- Transaction `(stage ...)` fails closed during scheduler validation with
  `Transaction '<tx>': pipeline '(stage ...)' clauses are parsed but not
  implemented by ISF lowering`.
- Transaction `(contract ...)` fails closed during scheduler validation with
  `Transaction '<tx>': temporal '(contract ...)' clauses are parsed but not
  implemented by ISF lowering`.
- Other unsupported transaction heads still use the generic
  `unsupported '(<head> ...)' clause` diagnostic; `stage` and `contract` keep
  the more specific diagnostics above.

Missing lowering hooks:

- There is no `stage` entry in `%SUPPORTED_TRANSACTION_CLAUSES`, and the
  scheduler rejects the head before `_build_transaction` can dispatch it.
- There is no `_ir_stage` builder, no valid/ready stage-state expansion, no
  stage-local storage/enable model, and no stage summary in `Emitter::JSON`.
- There is no `contract` entry in `%SUPPORTED_TRANSACTION_CLAUSES`, and the
  scheduler rejects the head before `_build_transaction` can dispatch it.
- There is no contract parser payload model, no temporal-check IR node, no
  generated assertion/check emitter, no reset/disable policy for checks, and
  no contract summary in `Emitter::JSON`.
- Actor-level phase/stage metadata is parser-carried only. Any future semantic
  use needs an explicit bridge from actor-shell metadata into LoweringIR and
  schedule-report metadata before generated artifacts depend on it.

## ISF-STAGES-CONTRACTS.2 Stage Semantics

The first planned shipped transaction-stage model is deliberately a handshake
barrier, not a general pipeline language. It gives authors a reviewable way to
hold a transaction at a protocol boundary until a downstream ready signal
accepts the stage.

Supported source shape for the first implementation:

```lisp
(stage name
  (input ready_signal)
  (output valid_signal))
```

Rules:

- `stage` is supported only as a top-level transaction clause in the first
  lowering slice. Stages nested inside `when`, `switch`, or `repeat` remain
  fail-closed until those control-flow compositions are specified.
- `name` must be the existing non-empty scalar stage name. The generated state
  name should use the transaction/state index, while schedule-report metadata
  preserves the authored stage name.
- Exactly one `(input ready_signal)` subclause is required. `ready_signal`
  must name a scalar actor input in the first implementation.
- Exactly one `(output valid_signal)` subclause is required. `valid_signal`
  must name a scalar actor output in the first implementation.
- Duplicate `input` or `output` subclauses are rejected.
- Unknown stage subclauses, including `(latency ...)`, `(compute ...)`,
  embedded transaction actions, or arbitrary property entries, are rejected for
  the first implementation even though the historical parser preserved them as
  metadata.

Generated scheduling behavior:

- The stage lowers to one transaction state at the point where it appears in
  the transaction clause stream.
- While that state is active, `valid_signal` is driven with a combinational
  `=` assignment to `1`.
- The state transitions to the next scheduled transaction state only when
  `ready_signal` is true. When `ready_signal` is false, the FSM remains in the
  stage state and keeps `valid_signal` asserted.
- The ready test reads the current-cycle value of `ready_signal`; it is not a
  delayed pulse and it is not sampled into implicit storage.
- If the next scheduled clause is `(complete done)`, the completion state is
  reached one cycle after the ready/valid handshake succeeds, preserving the
  existing `<1` completion-pulse contract.

Ordering and interaction guarantees:

- Clauses before the stage complete before the stage becomes active according
  to normal transaction state ordering.
- Pending `(sample port as name)` clauses immediately before a stage must be
  materialized before the stage state, so a stalled stage does not resample the
  port every cycle.
- Clauses after the stage do not execute until a cycle after
  `ready_signal && valid_signal` is observed while the stage state is active.
- The stage valid output is state-owned and one-hot with respect to that stage
  state. Leaving the state removes the stage's selector for `valid_signal`.

Deferred stage features:

- Actor-level stage metadata remains parser-carried only.
- Nested stages inside `when`, `switch`, and `repeat` remain fail-closed.
- Stage-local `(latency ...)`, `(compute ...)`, and arbitrary body actions are
  deferred until their generated-state and check/report semantics are
  specified.
- Multiple ready inputs, multiple valid outputs, skid/hold buffers,
  back-pressure propagation to earlier states, registered-valid variants, and
  multi-stage resource ownership are deferred.

## Decisions

- `2026-05-14`: Stage lowering and temporal contract lowering are tracked in
  one tree because both are transaction-local scheduling/checking metadata that
  currently fail closed at lowering time.

## Open Questions

- What is the smallest useful stage model that can be emitted as reviewable
  `.fsm` without hiding handshake timing?
- Should temporal contracts initially emit simulation assertions, scheduled
  check states, or both?

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-14` | `ISF-STAGES-CONTRACTS` | `git diff --check` | `passed` |
| `2026-05-14` | `ISF-STAGES-CONTRACTS.1` | `prove -l t/1175-isf-contract-fail-closed.t t/1179-isf-phase-stage-boundary.t t/1180-isf-unsupported-transaction-clause-boundary.t`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-14` | `ISF-STAGES-CONTRACTS.2` | `prove -l t/1179-isf-phase-stage-boundary.t t/1180-isf-unsupported-transaction-clause-boundary.t`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-STAGES-CONTRACTS` | `R14: map ISF objectives to task trees` | Initial tree creation belongs to the ISF objective task-tree coverage slice. |
| `ISF-STAGES-CONTRACTS.1` | `ISF-STAGES-CONTRACTS.1: inventory stage contract boundary` | Stage/contract parse and fail-closed inventory. |
| `ISF-STAGES-CONTRACTS.2` | `ISF-STAGES-CONTRACTS.2: specify bounded stage semantics` | First bounded transaction-stage semantics. |

## Changelog

- `2026-05-14`: Created the active ISF stage/contract task tree.
- `2026-05-14`: Completed the current stage/contract parser, preservation,
  diagnostic, and missing-lowering-hook inventory; advanced the frontier to
  `ISF-STAGES-CONTRACTS.2`.
- `2026-05-14`: Specified the first bounded transaction stage model as a
  top-level ready/valid handshake barrier and advanced the frontier to
  `ISF-STAGES-CONTRACTS.3`.
