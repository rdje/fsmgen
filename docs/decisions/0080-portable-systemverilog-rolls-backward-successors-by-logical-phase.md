# 0080 — Portable SystemVerilog rolls backward successors by logical phase

- Date: 2026-08-24
- Type: verification backend/runtime scheduling
- Status: accepted by `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.1.1`
- Refines: [0036](0036-vial-execution-is-deterministic-logical-time-above-backend-methodology.md), [0043](0043-vial-portable-systemverilog-is-a-deterministic-known-value-profile.md)
- Implementation owner: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.1.1`

## Context

The portable-SystemVerilog scenario task retained root operations in immutable
ExecutionIR array/static-rank order and called their generated tasks directly.
That preserved authored dependencies but did not preserve logical phase order
when a later authored action was eligible in an earlier phase.

An ordinary checked-AHB mutation placed a check-phase `expect` immediately
before a react-phase `scoreboard_expect`. The unmodified public Runner compiled
and ran the generated fixture under qualified Verilator 5.046, then rejected
the genuine trace as `VIAL_RUN_TRACE_ERROR`: the underlying validator observed
a cycle-4 tuple at phase rank 3 followed by cycle-4 phase rank 2. ExecutionIR
was correct; the emitter had no phase cursor and no next-cycle rollover.

The operation graph does not make dynamic completion cycles statically known.
`reset`, `start`, `await`, and `parallel` can consume cycles internally. It does,
however, fix the operation topology, authored static rank, eligible phase, and
closed operation kind. The backend also knows the last logical phase consumed
by each of its own generated operation-task lowerings. Those facts are enough
to schedule the next root operation without a second runtime interpreter.

## Decision

1. Keep the existing static-partial-evaluation architecture. Root operations
   execute in immutable ExecutionIR array/static-rank order; the backend does
   not sort them by phase or reinterpret source.
2. Maintain one closed backend compatibility table per supported operation
   kind. It records the ExecutionIR eligible phase and the last logical phase
   consumed by that generated task. Negotiation independently requires the
   exact `drive, sample, react, check` phase order and exact operation/eligible-
   phase pairs before emitting any artifact.
3. After each generated operation task, retain its lowering-completion phase as
   the scenario scheduler cursor. If the next operation's eligible phase is at
   or after that cursor, call it without a rollover. This preserves same-phase
   static-rank order and forward progress within one logical cycle.
4. If the next eligible phase ranks earlier, advance exactly once to its first
   legal phase in the next logical cycle. A target `drive` increments the
   logical cycle directly; a target `react` traverses the one qualified
   inactive-edge barrier so sample/react state is genuine. No version-1 action
   is sample-eligible, and no phase can roll backward to `check`.
5. Move drive-boundary advancement out of the `start` operation body and into
   this single successor scheduler. A first `start` may therefore execute in
   cycle-zero drive, while react/check-to-drive successors still advance once.
6. Keep simulator timestamps out of the rule. The trace records the logical
   time produced by actual generated behavior; neither the validator nor the
   result producer repairs timestamps after execution.
7. Treat operation-phase drift as an unsupported backend negotiation, not a
   host exception or best-effort emission. The failure publishes no partial
   backend artifact.

The compatibility table describes the current lowering, not a new public IR
field. In particular, direct `drive` currently consumes an inactive barrier in
the existing renderer. The same review independently proved that renderer does
not yet assign its requested endpoint; proposed prerequisite
`.17.3.5.1.2` owns that separate defect and must update the table and scheduler
proof when it repairs direct-drive semantics.

## Alternatives rejected

- **Globally sort by phase.** This violates authored dependencies and stable
  static ranks.
- **Insert a barrier between every operation.** This invents idle cycles,
  changes timeouts, and prevents legal same-cycle react/check chains.
- **Reject backward authored pairs.** The source is legal under the selected
  execution contract; backend limitations cannot silently narrow it after
  claiming the operation kinds.
- **Rewrite VIAL/generated source or trace timestamps.** This changes or
  fabricates the measured work instead of implementing it.
- **Add a dynamic target interpreter.** The immutable graph and closed lowering
  phases already determine the required transition; a second execution engine
  would add state and divergence without semantic benefit.

## Consequences and rollback

The emitted fixture gains concise rollover comments and only the scheduler
statements required by a backward crossing. Existing public API, ExecutionIR,
trace, result, source-map, and capability schemas remain unchanged. Generated
source/result identities legitimately change because the executable schedule
changes; identical repaired runs remain byte-deterministic.

Rollback is the single implementation slice: revert the phase compatibility
table, negotiation check, scenario cursor, centralized start advancement, and
their focused tests/documentation together. No migration or persisted-schema
conversion is required. Rolling back would restore the executable RED and must
therefore also withdraw the portable runtime's legal backward-successor claim.

## Verification legs

- **Re-derivation:** immutable ExecutionIR records prove authored ranks and
  `check`/`react` eligibility; source inspection and `git log
  -S'operation_by_scenario'` locate the cursor-free emitter at `dfe87f536`.
- **Falsification:** the real Runner RED reaches Verilator and fails only at
  deterministic trace order; structural mutations cover check-to-react,
  react-to-drive, check-to-drive, same-phase retention, and fail-closed phase
  drift.
- **Durability:** the backend contract, mdBook, Knowledge Map, owning task,
  executable tests, this decision, and Git history retain the rule. The
  separate direct-drive defect remains explicit rather than being hidden by
  this repair.
