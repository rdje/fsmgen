# Decision 0100: Portable SystemVerilog lifecycle uses a static check-seam controller

- **Status:** Accepted
- **Date:** 2026-09-04
- **Owner:** `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2`
- **Extends:** [0036](../../0036-vial-execution-is-deterministic-logical-time-above-backend-methodology.md), [0043](../../0043-vial-portable-systemverilog-is-a-deterministic-known-value-profile.md)

## Context

VIAL v2 now preserves a valid typed `lifecycle_control@1` graph through the
target-neutral plan. The portable-SystemVerilog route is still deliberately
v1-only at adapter, emitter, result, runner, and host-process lifecycle seams.
The private v1 trace validator has a narrower pre-existing defect: it verifies
the exact ExecutionIR object type but not its schema/version/profile envelope
before parsing a v1-shaped stream. Selecting the next mapping must not smuggle
simulator scheduling into VIAL meaning, reinterpret the existing scenario
graph, or relabel v2 data as qualified v1 evidence.

The v1 scheduler also resets its scenario cycle for each selected scenario,
whereas one lifecycle spans the fixture and all selected scenarios. Reusing
that scenario-local counter for lifecycle deadlines would make later scenarios
move logical time backward.

## Decision

1. Lower the typed lifecycle plan into one finite, statically emitted
   fixture-level controller beside the existing scenario scheduler. Emit no
   interpreter, dynamic process topology, class hierarchy, callback, UVM
   mechanism, DPI/VPI bridge, or host semantic callback.
2. Invoke the controller only at three compiler-owned check seams: after
   initialized configuration, after each inactive-edge barrier has committed
   its existing work, and after each scenario becomes terminal. One seam runs
   a deterministic fixed point in lifecycle semantic rank and ID order.
3. Preserve scenario-local cycle meaning and add one monotone lifecycle cycle
   counted from lifecycle entry across the whole selected fixture run. Every
   lifecycle time is `(domain, lifecycle_cycle, check, ordinal)`; a fixed-point
   transition increments only the ordinal, never the cycle.
4. Gate scenario admission on committed stimulus start. Scenario execution
   remains owned by the existing static scheduler. It publishes only terminal,
   transaction-active, and scoreboard-settled facts to the controller; neither
   scheduler calls into or reinterprets the other's plan.
5. On success, progress through dependency/service readiness, stimulus,
   scenario completion, service quiescence, drain, shutdown, service stop, and
   finalization. Conditions are monotone latches. Deadline checks run after
   reachable milestones at a seam, preserving inclusive `C + N - 1` behavior.
6. On the first scenario, service, deadline, trace, or controller failure,
   latch one primary cause, close admission, request cooperative cancellation
   and service stop, cancel unreached normal records, and run failure cleanup
   under its independent bound. Failure cleanup does not forge normal drain,
   shutdown, or finalize milestones. A failed lifecycle cannot return to pass.
7. Isolate v2 evidence with distinct backend, source-map, runtime-trace,
   trace-projection, and result-manifest schemas. The normalized
   `fsmgen.vial_lifecycle_result.v1` remains the family result nested in the v2
   result manifest because its meaning is already target-neutral and versioned.
8. Preserve the v1 emitter graph and public result bytes exactly. Reuse only
   genuinely version-independent bridge, command, and tool-profile schemas;
   never place v2 lifecycle records in a v1 trace or result envelope.
9. Keep every lifecycle backend maturity field unavailable in this selection.
   Emission, compilation, runtime, result production, parity, and public v2
   `run` advance only in their separately owned implementation/qualification
   children.

The exact state, record-to-control map, transition vocabulary, schemas,
source-map duties, artifact transaction, rejection order, and rollback are
canonical in
`docs/vial-spec/portable-systemverilog-lifecycle-v2.md`.

## Rejected alternatives

- Reusing scenario-local cycle state makes fixture lifecycle time non-monotone.
- A second independent clock/process gives target wake order semantic authority.
- Calling the host `VerilatorLifecycle` the VIAL lifecycle confuses bounded
  compile/run supervision with authored fixture meaning.
- Extending v1 trace/result schemas in place breaks exact compatibility and can
  make old consumers accept incomplete lifecycle evidence.
- Mapping lifecycle directly to UVM phases or objections violates target
  neutrality and does not describe the plain-SystemVerilog backend.

## Verification and consequences

- **Re-derive:** T1809 builds the maintained lifecycle plan and derives every
  record kind and controller operation sequence from typed ExecutionIR.
- **Falsify:** T1809 rejects premature adapter/runner/result admission, partial
  artifacts, mapping drift, and any change to the frozen v1 emitter or
  normalized-result digests. It also characterizes the private validator's
  present cross-version admission so repair child `.19.2.3.1.2.1` cannot be
  silently skipped before emitter work.
- **Durability:** this decision, the bounded VIAL part, T1809, the mdBook,
  Knowledge Map, task tree, and work-unit commit retain the selection.

Rollback removes only those selection artifacts. It does not edit v1 behavior
or the already implemented target-neutral lifecycle compiler. The trace
validator isolation repair is a required child of this selection, not a
backend-availability claim.
