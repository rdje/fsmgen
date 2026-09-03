# Decision 0097: Regression gates publish replaceable observations without recalibrating

- **Status:** Accepted
- **Date:** 2026-09-03
- **Owner:** `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.1`
- **Refines:** [0056](0056-vial-scale-measurements-use-pinned-evidence-and-bounded-failure.md), [0096](0096-regression-promotion-uses-a-current-eleven-profile-corpus.md)

## Context

The current regression-promotion qualification is an immutable two-file seal.
It binds the eleven selected workloads, their exact non-timing correctness
projections, Decision 0056 budgets, host/tool/guard/provider applicability, and
recalibration rules. Its publication contract deliberately says that the seal
itself does not activate enforcement.

A regression gate has a different lifecycle. It must execute the same eleven
canonical adapter routes at a later clean revision, produce one validation and
three raw measurements per profile, compare deterministic results exactly, and
classify timing using the frozen qualification. Unlike calibration evidence,
the gate result is a repeatable observation. Wall, CPU, and RSS measurements
may differ between repeated correct runs, so storing a result at one immutable
coordinate would make the second run collide. Accumulating one permanent
directory per invocation would instead create unbounded generated state.

The gate also needs one non-bypassable applicability order. A fast incorrect
run cannot pass; a caller cannot request informational performance on the
pinned host; and an unavailable exact provider cannot be renamed pass merely
because hosted CI lacks it.

## Decision

1. `FSM::VIAL::ArchitectureScaleRegressionPromotionGateContract` is the
   caller-sealed metadata authority. Public derivation accepts only the
   repository root beneath the active RAM guard, loads the authenticated
   qualification, independently derives the current capture plan, joins all
   ordered dispatch and qualification fields, and returns defensive canonical
   data. Derivation executes no producer, provider, simulator, measurement
   controller, or result publication.
2. Each gate run invokes all eleven selected adapter routes in plan order. Each
   adapter call owns one fresh validation plus three fresh raw measurements in
   one guard-visible profile worker. The execution revision is clean current
   provenance; it is not an applicability field and does not replace the
   qualification's capture or publisher revision.
3. Admission order is correctness, deterministic identity, provider status,
   environment applicability, then performance. Selection key, workload
   identity, and correctness projection are exact. Any mismatch rejects before
   timing is classified. Safety, bounded failure, atomicity, and cleanup remain
   mandatory in every applicable environment.
4. For each metric, the gate compares the maximum across all three fresh raw
   records with the corresponding frozen budget. Performance is enforced only
   when the complete qualified host, tool, resource-guard, and provider fields
   match. Environment mismatch keeps correctness mandatory and makes
   performance informational. An unavailable required provider has the
   distinct result `unavailable`, never `pass`.
5. No caller flag can downgrade enforcement or replace any applicability
   field. Hosted CI naturally receives informational performance because its
   declared Ubuntu/tool environment differs from the pinned Apple M4 Pro
   qualification; this follows from authenticated identity, not a CI bypass.
6. A completed aggregate gate result is one bounded canonical observation at
   `.artifacts/qualification/vial-scale/v2/regression-promotion-gate-v1/current/regression-promotion-gate-result.json`.
   The writer uses repository-local same-volume staging, validates the complete
   result, and atomically replaces the previous observation only after success.
   Interruption preserves the previous valid result and leaves no staging.
7. The replaceable result is never qualification evidence, a calibration
   sample, or recalibration authority. It cannot overwrite the qualification,
   change a budget, or become a source for a later budget. The result content
   retains its own identity and exact qualification/file-set references so CI
   output and a local latest observation remain auditable.
8. Result encoding is capped at 1,048,576 bytes and one sanitized diagnostic at
   4,096 bytes. A profile report retains the existing 67,108,864-byte
   publication ceiling, while child-to-parent metadata retains the existing
   65,536-byte IPC ceiling. These are storage and transport containment bounds,
   not performance or capacity claims.
9. Ordinary slice commits run the contract watcher and changed-path focused
   checks only. The complete guarded gate belongs to full pre-push and selected
   important steps. Hosted placement runs available correctness,
   determinism, safety, publication, and cleanup; performance classification
   remains identity-derived. `.17.5.4.3` owns the exact workflow wiring.

## Alternatives rejected

- **Overwrite or amend the qualification after a successful gate:** this would
  let the measured run change its own threshold and destroy immutable evidence.
- **Store every invocation permanently:** content addressing would avoid
  collisions but would create an unbounded generated-result namespace.
- **Use one immutable result coordinate:** repeated correct measurements have
  different timing values and would collide.
- **Let `--informational` or a CI variable suppress performance:** a caller
  could then bypass a real pinned-host regression.
- **Skip the whole gate when one provider is absent:** available correctness
  paths would disappear, while absence could be mistaken for a pass.
- **Compare median current timing:** one over-budget run would be hidden even
  though Decision 0056 defines a hard budget over the calibration maximum.

## Verification legs

- **Re-derive:** run the guarded exact t1785 path. It must authenticate the real
  qualification publication and file set, join all eleven plan/profile
  bindings, reproduce the 11/33/44 topology, copy every budget without
  recalculation, and return contract identity
  `regression-promotion-gate-contract/0150f4b39e1d099eec9a592c1abd1c75ed2758efff0ccf1514ec57599179e368`.
- **Falsify:** t1785 begins RED while the authority is absent, poisons every
  work entrypoint during derivation, and rejects plan, order, manifest,
  provider, correctness, budget, applicability, immutability, schema, and
  dispatch mutations. Caller evidence, absent guard, and borrowed invocants
  reject; returned nested values are defensive.
- **Durability:** retain this decision, the contract module, t1785, the owning
  task, synchronized mdBook and Knowledge Map truth, bounded claim record,
  doctrine gates, and work-unit Git commit. Implementation, CI placement, and
  independent runtime closeout remain separately owned children.

## Consequences and nonclaims

- The implementation child has one closed input/output and applicability
  design; it does not need to reinterpret the qualification.
- Repeated runs are safe without accumulating permanent per-invocation state
  or weakening crash recovery.
- This selection activates no producer, provider, simulator, measurement
  controller, result publication, performance enforcement, performance result,
  support tier, or architecture-scale capacity claim.

## Rollback

Before gate implementation, rollback removes this decision, the contract
authority, its watcher, and synchronized references, then returns `.17.5.4.1`
to active. After implementation, remove gate and CI consumers before removing
the contract. Rollback never edits or retires the immutable qualification.
