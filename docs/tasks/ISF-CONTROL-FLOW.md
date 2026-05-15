# ISF-CONTROL-FLOW: Transaction Waits And Dynamic Loops

## Metadata

- Tree ID: `ISF-CONTROL-FLOW`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-15`
- Last updated: `2026-05-15`
- Owner: repo-local workflow

## Goal

Specify and eventually implement transaction-local control-flow constructs for
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
  Status: `active`
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
  Status: `pending`
  Goal: Implement positive-literal `(wait N)`.
  Acceptance: Transaction bodies accept `(wait N)` for positive integer
  literal N, lower to reviewable scheduled `.fsm`, report generated wait
  storage/states as needed, reject malformed or unsupported counts with
  targeted diagnostics, and reach SystemVerilog generation.
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-CONTROL-FLOW.3`
  Status: `pending`
  Goal: `Implement dynamic transaction loops.`
  Acceptance: `(while cond body...)` lowers as a pre-test zero-or-more loop,
  `(until cond body...)` lowers as a body-first one-or-more loop, conditions
  are sampled once per generated decision state, supported bodies match the
  specified transaction body surface, malformed loops fail closed, and focused
  regressions prove scheduled `.fsm`, report, and HDL generation behavior.
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-CONTROL-FLOW.2` | `pending` | The source/runtime contract is specified; positive-literal `(wait N)` is the smallest executable implementation slice before dynamic loops. |

## Design Notes

- `(wait N)` is an exact-cycle transaction delay with no external condition.
  The first proposed surface should use a positive integer literal count so
  the scheduled `.fsm` review artifact is fixed and easy to inspect.
- Dynamic wait counts are useful but need zero-count, counter-width, reset,
  latency, and schedule-report semantics before they can ship.
- `(while cond body...)` is proposed as a pre-test loop. The generated decision
  state samples `cond` before each possible iteration; false exits.
- `(until cond body...)` is proposed as a body-first loop. The body executes
  once, then a generated decision state samples `cond`; true exits and false
  loops.
- A pre-test "run while not done" loop should be authored as
  `(while (! done) body...)` rather than overloading `until`.
- Loop bodies are persistent hardware schedule regions, not software calls.
  The implementation must make re-entry, child spawn/call behavior, and
  unbounded-latency reporting explicit for any body forms it enables.
- First shipped loop bodies should use the current inline-body subset:
  named drive calls, `await`, `sample`, `complete`, `repeat`, `update`,
  shift/assemble/extract data operations, nested `when`, and shipped `wait`
  clauses. `do`, `spawn`, `await_all`, `await_any`, `stage`, `contract`, and
  nested `while`/`until` remain deferred until re-entry, child lifetime, and
  reporting semantics are specified.

## Decisions

- `2026-05-15`: Record `(wait N)` as a real missing transaction construct for
  unconditional exact-cycle delay.
- `2026-05-15`: Use `while` for pre-test zero-or-more loops and `until` for
  body-first one-or-more loops unless a later specification leaf changes the
  contract before implementation.
- `2026-05-15`: Activate this tree for R14 PNT. The first shipped wait surface
  is `(wait N)` with positive integer literal `N >= 1`; dynamic counts and
  zero-count behavior remain deferred.
- `2026-05-15`: `wait 1` means one active transaction cycle in a generated
  wait region, then advance on the next state transition. `wait N` contributes
  exactly `N` active cycles wherever it executes, including inside future
  loops.
- `2026-05-15`: Loop conditions are sampled only in generated decision states.
  They are not continuously active guards over multi-cycle loop bodies.
- `2026-05-15`: Successful reports should grow bounded `transaction_waits[]`
  and `transaction_loops[]` summaries when those constructs ship; raw lowering
  internals and raw parser clauses remain private.

## Open Questions

- Should dynamic `(wait count)` ship before or after literal `(wait N)`?
- Which loop body forms should be accepted in the first implementation if
  spawned children or child calls can create re-entry hazards?
- Should loop summaries appear as their own schedule-report family or only as
  generated transaction states and storage?

## Blockers

- None. The tree is active; implementation proceeds one leaf at a time.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-15` | `ISF-CONTROL-FLOW.1` | `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-CONTROL-FLOW.1` | `ISF-CONTROL-FLOW.1: specify wait and loop contracts` | Activates the tree and records exact wait-cycle semantics plus loop sampling/body/report boundaries. |

## Changelog

- `2026-05-15`: Created the proposed transaction wait/loop task tree from the
  `(wait N)`, `(while ...)`, and `(until ...)` design discussion.
- `2026-05-15`: Activated the tree and completed `ISF-CONTROL-FLOW.1`; the
  current frontier is `ISF-CONTROL-FLOW.2`.
