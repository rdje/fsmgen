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
  Status: `done`
  Goal: `Specify first bounded temporal contract semantics.`
  Acceptance: `The tree records supported temporal assertions/checks,
  generated artifact shape, reset behavior, report metadata, and rejected
  contract forms.`
  Verification: `prove -l t/1175-isf-contract-fail-closed.t t/1180-isf-unsupported-transaction-clause-boundary.t`;
  `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-STAGES-CONTRACTS.3: specify bounded contract semantics`

- ID: `ISF-STAGES-CONTRACTS.4`
  Status: `done`
  Goal: `Implement stage lowering.`
  Acceptance: `Covered stage forms lower into scheduled FSM, parse through
  the normal frontend, and generate HDL/check artifacts as specified.`
  Verification: `prove -l t/1179-isf-phase-stage-boundary.t t/1180-isf-unsupported-transaction-clause-boundary.t t/1223-isf-stage-lowering.t t/1144-isf-public-tested-by-metadata-audit.t`;
  `./bin/ci-regression isf --no-book`; `mdbook build docs/book`;
  `git diff --check`
  Commit: `ISF-STAGES-CONTRACTS.4: implement bounded stage lowering`

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
| 1 | `ISF-STAGES-CONTRACTS.5` | `pending` | The contract model is specified and can now be lowered into scheduled monitor logic. |

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

## ISF-STAGES-CONTRACTS.3 Contract Semantics

The first planned temporal-contract model is a transaction-local bounded
eventual check. It is intentionally smaller than a full temporal assertion
language and is designed to lower into reviewable scheduled `.fsm` before any
backend assertion emission happens.

Supported source shape for the first implementation:

```lisp
(contract name
  (eventually signal (within cycles)))
```

Rules:

- `contract` is supported only as a top-level transaction clause in the first
  lowering slice. Contracts nested inside `when`, `switch`, or `repeat` remain
  fail-closed until those control-flow compositions are specified.
- `name` must be a non-empty scalar contract name and must be unique within
  its transaction.
- `signal` must be a scalar actor interface input or output in the first
  implementation. Broader internal/inferred signal references are deferred
  until the signal-resolution contract is explicit.
- `cycles` must be a positive integer literal. Dynamic bounds and min/max
  windows are deferred.
- The contract is armed when the transaction reaches the contract clause. It
  is not a global `always` property and it does not inspect cycles before the
  arm state.
- The checked window starts on the cycle after the arm state and ends after
  `cycles` checked cycles. The signal may satisfy the obligation in any checked
  cycle up to and including the final cycle.

Generated scheduled-artifact shape:

- The contract clause lowers to one transaction state at its source position.
  That state emits a one-cycle internal arm request and falls through to the
  next scheduled transaction state.
- A generated always-on non-state monitor DT owns the contract storage. The
  monitor has a pending bit, an age counter wide enough for `cycles`, and a
  sticky fail bit.
- When the arm request is observed while no obligation is pending, the monitor
  sets pending and clears the age counter.
- While pending, seeing `signal` clear the obligation. If the final checked
  cycle expires without `signal`, the monitor sets the sticky fail bit.
- If a new arm request arrives while the same contract is still pending, the
  monitor sets the same sticky fail bit. This is the first overlap policy:
  one outstanding obligation per contract instance.
- The sticky fail bit remains set until actor reset. It is a verification
  status signal, not a transaction completion signal.

Reset and HDL check policy:

- Actor reset disables the monitor and clears pending, age, and fail storage.
  The reset polarity and sync/async behavior follow the actor's existing reset
  lowering.
- Generated SystemVerilog may add a verification-only assertion under
  `` `ifndef SYNTHESIS`` that checks the sticky fail bit remains zero. Verilog
  emission may keep only the generated monitor storage without an assertion.
- The scheduled `.fsm` monitor remains the source of truth. Backend assertions
  are a projection of that monitor, not an alternate SVA-only lowering path.

Planned schedule-report metadata:

- Successful reports should include a bounded `temporal_contracts` array.
- Each entry should include: `transaction`, `name`, `kind` =
  `bounded_eventually`, `trigger` = `contract_state`, `signal`,
  `within_cycles`, `pending_signal`, `counter_signal`, `fail_signal`,
  `overlap_policy` = `fail`, `reset_policy`, and `assertion_projection`.
- Raw monitor equations, raw `LoweringIR`, and backend assertion text are not
  public schedule-report payloads.

Rejected or deferred contract forms:

- Historical/free-form examples such as
  `(contract (always request -> eventually[1..8] grant))` remain fail-closed
  until a real temporal grammar is specified for them.
- Antecedent/consequent implication forms, global `always` monitoring,
  same-cycle windows, min/max windows, unbounded liveness, dynamic bounds,
  overlapping-obligation queues, multiple consequent signals, expression
  operands, nested contracts, and contract actions are deferred.
- Contracts that would collide with generated monitor names fail before
  scheduled artifact emission.

## ISF-STAGES-CONTRACTS.4 Stage Implementation

Shipped behavior:

- `%SUPPORTED_TRANSACTION_CLAUSES` now accepts `stage` only in top-level
  transaction bodies.
- The lowerer validates the first bounded source shape exactly as
  `(stage name (input ready_signal) (output valid_signal))`, with one scalar
  actor input and one scalar actor output.
- The generated stage state is named `<transaction>_stage_<index>`, drives
  `valid_signal = 1` with a combinational `=` assignment while active, and
  transitions to the next state only under `<ready_signal`.
- Pending samples immediately before a stage are flushed to a separate sample
  state before the stage, so a stalled stage does not recapture source ports.
- Nested stages in `when`, `switch`, and `repeat`, unsupported stage body
  entries such as `(latency ...)`, and endpoint direction mismatches fail
  closed with targeted diagnostics.
- The generated scheduled `.fsm` parses through the normal `.fsm` frontend and
  reaches SystemVerilog generation in `t/1223-isf-stage-lowering.t`.

Deferred to later leaves or backlog:

- Schedule-report stage metadata is deferred to `ISF-STAGES-CONTRACTS.6`.
- Stage-local latency, compute/action bodies, multiple endpoints,
  registered-valid variants, skid buffers, and nested stages remain backlog
  until their runtime and report contracts are specified.

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
| `2026-05-14` | `ISF-STAGES-CONTRACTS.3` | `prove -l t/1175-isf-contract-fail-closed.t t/1180-isf-unsupported-transaction-clause-boundary.t`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-14` | `ISF-STAGES-CONTRACTS.4` | `prove -l t/1179-isf-phase-stage-boundary.t t/1180-isf-unsupported-transaction-clause-boundary.t t/1223-isf-stage-lowering.t t/1144-isf-public-tested-by-metadata-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-STAGES-CONTRACTS` | `R14: map ISF objectives to task trees` | Initial tree creation belongs to the ISF objective task-tree coverage slice. |
| `ISF-STAGES-CONTRACTS.1` | `ISF-STAGES-CONTRACTS.1: inventory stage contract boundary` | Stage/contract parse and fail-closed inventory. |
| `ISF-STAGES-CONTRACTS.2` | `ISF-STAGES-CONTRACTS.2: specify bounded stage semantics` | First bounded transaction-stage semantics. |
| `ISF-STAGES-CONTRACTS.3` | `ISF-STAGES-CONTRACTS.3: specify bounded contract semantics` | First bounded temporal-contract semantics. |
| `ISF-STAGES-CONTRACTS.4` | `ISF-STAGES-CONTRACTS.4: implement bounded stage lowering` | First bounded transaction-stage lowering. |

## Changelog

- `2026-05-14`: Created the active ISF stage/contract task tree.
- `2026-05-14`: Completed the current stage/contract parser, preservation,
  diagnostic, and missing-lowering-hook inventory; advanced the frontier to
  `ISF-STAGES-CONTRACTS.2`.
- `2026-05-14`: Specified the first bounded transaction stage model as a
  top-level ready/valid handshake barrier and advanced the frontier to
  `ISF-STAGES-CONTRACTS.3`.
- `2026-05-14`: Specified the first bounded temporal contract model as a
  transaction-local bounded eventual monitor and advanced the frontier to
  `ISF-STAGES-CONTRACTS.4`.
- `2026-05-14`: Implemented the first bounded transaction-stage lowering path
  and advanced the frontier to `ISF-STAGES-CONTRACTS.5`.
