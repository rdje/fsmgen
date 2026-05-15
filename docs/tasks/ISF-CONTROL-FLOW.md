# ISF-CONTROL-FLOW: Transaction Waits And Dynamic Loops

## Metadata

- Tree ID: `ISF-CONTROL-FLOW`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-15`
- Last updated: `2026-05-15`
- Owner: repo-local workflow

## Goal

Specify and implement transaction-local control-flow constructs for
unconditional cycle waits and dynamic loops, without blurring their runtime
semantics with `(await ...)`, `(repeat ...)`, or rule guards.

## Non-Goals

- Do not treat parser acceptance as shipped support before lowering,
  diagnostics, reports, tests, and mdBook/spec updates exist.
- Do not overload `(await cond)` to mean an unconditional delay.
- Do not model an exact-cycle wait as a fake empty repeat body.
- Do not interpret loop conditions as continuously active guards over every
  state inside a body; conditions must have explicit sampling points.

## Acceptance Criteria

- `(wait N)` has a public source contract, lowering path, exact cycle meaning,
  diagnostics, report visibility, and focused tests.
- `(while cond body...)` and `(until cond body...)` have distinct public
  semantics, lowering paths, diagnostics, report visibility, and focused
  tests.
- The mdBook, `docs/ISF_SPEC.md`, `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md`,
  live docs, and machine-readable public contract are synchronized for each
  shipped slice.
- Dynamic or unbounded behavior has an explicit watchdog/latency/reset/report
  policy before parser acceptance is considered public support.

## Task Tree

- ID: `ISF-CONTROL-FLOW`
  Status: `done`
  Goal: `Add transaction-local unconditional waits and dynamic loops.`
  Children: `ISF-CONTROL-FLOW.1`, `ISF-CONTROL-FLOW.2`,
  `ISF-CONTROL-FLOW.3`

- ID: `ISF-CONTROL-FLOW.1`
  Status: `done`
  Goal: `Specify the wait and loop contracts before implementation.`
  Acceptance: The task tree, mdBook, spec, and live docs define `(wait N)`,
  `(while cond body...)`, and `(until cond body...)`, including condition
  sampling, cycle accounting, watchdog/latency interaction, reset behavior,
  body-clause support, diagnostics, and report surfaces.
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-CONTROL-FLOW.1: specify wait and loop contracts`

- ID: `ISF-CONTROL-FLOW.2`
  Status: `done`
  Goal: Implement positive-literal `(wait N)`.
  Acceptance: Transaction bodies accept `(wait N)` for positive integer
  literal N, lower to reviewable scheduled `.fsm`, report generated wait
  storage/states as needed, reject malformed or unsupported counts with
  targeted diagnostics, and reach SystemVerilog generation.
  Verification: `prove -I perl t/1244-isf-wait-clause-lowering.t t/1181-isf-rule-action-boundary.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-CONTROL-FLOW.2: ship literal wait lowering`

- ID: `ISF-CONTROL-FLOW.3`
  Status: `done`
  Goal: `Implement dynamic transaction loops.`
  Acceptance: `(while cond body...)` lowers as a pre-test zero-or-more loop,
  `(until cond body...)` lowers as a body-first one-or-more loop, conditions
  are sampled once per generated decision state, supported bodies match the
  specified transaction body surface, malformed loops fail closed, and focused
  regressions prove scheduled `.fsm`, report, and HDL generation behavior.
  Verification: `perl -I perl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -I perl -c perl/FSM/Scheduler/ISF/Emitter/FSM.pm`; `perl -I perl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm`; `perl -I perl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `perl -I perl -c t/1245-isf-transaction-loop-lowering.t`; `prove -I perl t/1245-isf-transaction-loop-lowering.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-CONTROL-FLOW.3: ship transaction loops`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | All leaves in this tree are complete. |

## Design Notes

- `(wait N)` is an exact-cycle transaction delay with no external condition.
  The first proposed surface should use a positive integer literal count so
  the scheduled `.fsm` review artifact is fixed and easy to inspect.
- Dynamic wait counts are useful but need counter-width, reset, latency, and
  schedule-report semantics before they can ship. Zero-count wait behavior
  later shipped under `ISF-WAIT-ZERO`.
- `(while cond body...)` is shipped as a pre-test loop. Generated entry and
  back-edge decision states sample `cond` before each possible iteration;
  false exits.
- `(until cond body...)` is shipped as a body-first loop. The body executes
  once, then a generated decision state samples `cond`; true exits and false
  loops.
- A pre-test "run while not done" loop should be authored as
  `(while (! done) body...)` rather than overloading `until`.
- Loop bodies are persistent hardware schedule regions, not software calls.
  The implementation must make re-entry, child spawn/call behavior, and
  unbounded-latency reporting explicit for any body forms it enables.
- First shipped loop bodies use the current inline-body subset:
  named drive calls, `await`, `sample`, `complete`, `repeat`, `update`,
  shift/assemble/extract data operations, actor-owned bank `store`/`load`,
  nested `when`, and shipped `wait` clauses. `do`, `spawn`, `await_all`,
  `await_any`, `stage`, `contract`, and nested `while`/`until` remain
  deferred until re-entry, child lifetime, and reporting semantics are
  specified.

## Decisions

- `2026-05-15`: Record `(wait N)` as a real missing transaction construct for
  unconditional exact-cycle delay.
- `2026-05-15`: Use `while` for pre-test zero-or-more loops and `until` for
  body-first one-or-more loops unless a later specification leaf changes the
  contract before implementation.
- `2026-05-15`: Activate this tree for R14 PNT. The first shipped wait surface
  is `(wait N)` with positive integer literal `N >= 1`; dynamic counts remain
  deferred, and zero-count behavior later shipped under `ISF-WAIT-ZERO`.
- `2026-05-15`: `wait 1` means one active transaction cycle in a generated
  wait region, then advance on the next state transition. `wait N` contributes
  exactly `N` active cycles wherever it executes, including inside future
  loops.
- `2026-05-15`: Loop conditions are sampled only in generated decision states.
  They are not continuously active guards over multi-cycle loop bodies.
- `2026-05-15`: Successful reports use bounded `transaction_waits[]` and
  `transaction_loops[]` summaries for the shipped control-flow surface; raw
  lowering internals and raw parser clauses remain private.
- `2026-05-15`: Positive-literal `(wait N)` now lowers as a fixed generated
  wait-state chain with no hidden counter; `transaction_waits[]` reports the
  exact count, entry state, exit state, and a null `counter_signal`.
- `2026-05-15`: Zero-count wait behavior later shipped under
  `ISF-WAIT-ZERO`: `(wait 0)` is a no-op with no generated wait state and no
  `transaction_waits[]` entry.
- `2026-05-15`: Top-level transaction `(while cond body...)` and
  `(until cond body...)` now lower to explicit scheduled loop decision/body
  regions. `transaction_loops[]` reports transaction, kind, condition,
  generated decision/body states, exit state, and body clause count. Empty
  loop-body list nodes and unsupported loop-body combinations fail closed.

## Deferred Follow-Up

- Dynamic `(wait count)` and symbolic wait counts remain deferred until width,
  reset, latency, and report semantics are specified.
- Loop bodies containing `do`, `spawn`, `await_all`, `await_any`, `stage`,
  `contract`, or nested `while`/`until` remain deferred until re-entry,
  child-lifetime, and report semantics are specified.
- This tree is closed; reopen a new task-tree leaf if one of those follow-ups
  becomes the selected R14 feature.

## Blockers

- None. The tree is complete.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-15` | `ISF-CONTROL-FLOW.1` | `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-15` | `ISF-CONTROL-FLOW.2` | `prove -I perl t/1244-isf-wait-clause-lowering.t t/1181-isf-rule-action-boundary.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-15` | `ISF-CONTROL-FLOW.3` | `perl -I perl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -I perl -c perl/FSM/Scheduler/ISF/Emitter/FSM.pm`; `perl -I perl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm`; `perl -I perl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `perl -I perl -c t/1245-isf-transaction-loop-lowering.t`; `prove -I perl t/1245-isf-transaction-loop-lowering.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-CONTROL-FLOW.1` | `ISF-CONTROL-FLOW.1: specify wait and loop contracts` | Activates the tree and records exact wait-cycle semantics plus loop sampling/body/report boundaries. |
| `ISF-CONTROL-FLOW.2` | `ISF-CONTROL-FLOW.2: ship literal wait lowering` | Ships positive-literal `(wait N)` lowering, report metadata, diagnostics, and HDL-reachability coverage. |
| `ISF-CONTROL-FLOW.3` | `ISF-CONTROL-FLOW.3: ship transaction loops` | Ships top-level transaction `while`/`until` lowering, report metadata, diagnostics, and HDL-reachability coverage. |

## Changelog

- `2026-05-15`: Created the proposed transaction wait/loop task tree from the
  `(wait N)`, `(while ...)`, and `(until ...)` design discussion.
- `2026-05-15`: Activated the tree and completed `ISF-CONTROL-FLOW.1`; the
  current frontier is `ISF-CONTROL-FLOW.2`.
- `2026-05-15`: Completed implementation work for `ISF-CONTROL-FLOW.2`;
  positive-literal `(wait N)` now lowers to fixed wait-state chains and the
  current frontier advances to `ISF-CONTROL-FLOW.3`.
- `2026-05-15`: Completed implementation work for `ISF-CONTROL-FLOW.3`;
  top-level transaction `while`/`until` loops now lower to explicit scheduled
  decision/body regions, bounded `transaction_loops[]` report metadata is
  public, and the tree is closed.
