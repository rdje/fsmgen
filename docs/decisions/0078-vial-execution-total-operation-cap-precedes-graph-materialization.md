# 0078 — VIAL total-operation cap precedes operation-graph materialization

- Date: 2026-08-23
- Type: verification architecture/limit enforcement
- Status: selected by `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.3.2.1`
- Refines: [0036](0036-vial-execution-is-deterministic-logical-time-above-backend-methodology.md), [0055](0055-vial-scale-proof-uses-orthogonal-workloads-and-stage-local-oracles.md), [0056](0056-vial-scale-measurements-use-pinned-evidence-and-bounded-failure.md), [0061](0061-vial-execution-scale-uses-a-caller-sealed-qualification-binder.md)
- Implementation owner: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.3.2.1`

## Context

The clean revision-`b9463c6` execution/checking matrix runs each profile in a
separate guard-visible process. It publishes profiles one through nineteen,
then the isolated `operations_total/over_limit_v1` worker reaches 4,869.5 MiB
and the unchanged 4,096-MiB guard terminates it with exit status 137. The
coordinator no longer owns any full report, so this run falsifies retained
coordinator heap as the remaining cause.

`FSM::VIAL::ExecutionBuilder::_build_operations` emits every selected operation
and its source map, concatenates all scenario graphs, and only then calls
`_limit('expanded_operations_total', ...)`. The selected excess therefore
allocates nearly the entire 1,000,001-operation graph merely to return the
known `expanded_operations_total exceeds the limit 1000000` diagnostic. The
older exact `t/1626` boundary proof explicitly asks for a 6,144-MiB descendant
guard, while decision `0056` fixes architecture measurement at 4,096 MiB and
forbids host exhaustion as limit enforcement.

This count does not need to be guessed or borrowed from a caller.
`SemanticBuilder` computes each scenario's exact expanded `action_count` from
the compact typed action tree, including parallel fibers and literal repeats,
and rejects any scenario above 65,536 before constructing the private exact
`SemanticIR`. `ExecutionBuilder` receives only that exact object and already
selects the precise scenario set before building bindings or operations.

## Decision

1. Preserve the public and private execution entrypoints, the selected
   1,000,000 `expanded_operations_total` cap, all accepted-profile semantics,
   and the exact existing `VIAL_EXECUTION_LIMIT_ERROR` phase, message,
   semantic path, source-location, bridge-path, and related-record shape.
2. Immediately after exact scenario selection, independently walk each compact
   action tree and rederive its expanded operation count. Count the action
   record itself, every parallel-fiber body, and every literal-repeat body
   multiplied by its validated count. Require byte-level integer validity and
   exact equality with that scenario's `SemanticBuilder` `action_count`.
3. Aggregate those independently rederived selected-scenario counts with
   bounded arithmetic and invoke the existing total-operation limit before
   bridge indexing, fixture binding, execution-type registration, operation or
   source-map construction, plan serialization, or partial artifact creation.
4. Retain the existing post-materialization total-operation check as defense in
   depth. Accepted profiles must still build the byte-identical ExecutionIR and
   plan; an internal count disagreement must fail closed and cannot be treated
   as an ordinary limit rejection.
5. Keep `operations_total/over_limit_v1` as an observed product
   `expected_rejection`, not a synthesized scale-generator
   `preflight_dominated` result. Exact qualification must prove that the graph
   constructor is not entered, the historical diagnostic is unchanged, the
   4,096-MiB guard passes, and no staging or publication residue remains.
6. This prerequisite advances one concrete obligation already assigned to
   `.17.4`. It does not activate or close that broader cross-layer cap-policy
   task, which must still audit all remaining resource limits and interactions.

## Consequences

- A structurally known excess fails at the earliest authoritative execution
  stage without allocating a million-record graph or weakening the guard.
- The matrix continues to exercise ordinary parsing and canonical bridge
  construction; only avoidable execution-graph materialization is removed.
- Existing diagnostics, outcomes, source meaning, support, capabilities,
  performance budgets, and capacity claims do not change.
- The exact failed prefix remains immutable revision-keyed evidence. A later
  implementation revision must earn a fresh common-identity matrix rather than
  relabel or mix those reports.
