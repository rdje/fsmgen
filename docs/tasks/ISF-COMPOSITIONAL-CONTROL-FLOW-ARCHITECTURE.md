# ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE

Status: active

Roadmap lane: R14 / ISF compositional control-flow and activation architecture

Created: 2026-06-10

Current frontier: `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.7.5`

## Goal

Replace one-off control-flow/activation combination enablement with a
compositional architecture: every control-flow construct exposes a typed region
contract, and every activation/synchronization construct exposes typed effects
over child starts, child completions, loop backedges, outstanding-child
lifetime, binding/domain requirements, generated-child identity, and public
report/doc surfaces.

The target end state is "support combinations by construction": a new
combination is accepted because the region/effect contracts prove the hardware
invariants, not because a hand-written allow-list names that exact syntax path.

## Hardware Invariants

Every implementation leaf must preserve these invariants:

- A spawned/static child must not be restarted before its previous activation is
  drained or explicitly given a proven lifetime rule.
- Loop backedges must be dominated by required child completion checks.
- `await_any` observes completion; it does not drain all outstanding children.
- Generated children must have deterministic static instance names and complete
  generated-top wiring before a source shape is accepted.
- Bindings, domains, and CDC cannot be inferred implicitly; they must be
  represented as explicit typed effects and fail closed without a proven
  contract.
- Reports, diagnostics, mdBook, and spec wording must match emitted hardware.

## Non-Goals

- Do not flip all deferred combinations on at once.
- Do not silently accept a shape because the recursive lowerer happens to emit
  states for it.
- Do not introduce dynamic hardware creation or runtime-mutable parameter
  specialization.
- Do not infer CDC, binding direction, or grouping semantics from nesting alone.
- Do not delete existing hardcoded guards before shadow-mode parity proves the
  replacement contracts.

## Acceptance

- A task-tree and decision record own the architecture before any code change.
- A shadow typed-region/effect model is introduced first and validated against
  existing shipped and fail-closed fixtures without changing behavior.
- The model covers at least:
  - region entry and normal exits;
  - loop backedges;
  - branch and loop conditions;
  - local and generated child starts;
  - child done observations and drains;
  - outstanding child sets;
  - binding/domain/CDC requirements;
  - deterministic generated instance identity.
- Existing shipped combinations remain accepted.
- Existing unsupported combinations remain fail-closed until a later leaf proves
  the invariants from region/effect data.
- mdBook/spec/Knowledge Map/task-tree evidence stays synced at every slice.

## Task Tree

### ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.1 — Charter And Architecture Decision

Status: done

Goal: Activate the architecture workstream and record the cross-cutting
decision to move from enumerated syntax combinations to typed region/effect
contracts.

Acceptance:

- This task tree is active in `docs/TASK_TREE.md`.
- Decision `0013` records the architecture direction and rollout constraints.
- `MEMORY.md` points at the first implementation leaf.
- No code/test/source/config behavior change occurs in this slice.

Evidence:

- Selected `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.2.1` as the first
  implementation leaf because the safe migration path is a read-only
  region/effect inventory that can prove parity before any validator widening.

### ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.2 — Shadow Typed Region/Effect Model

Status: done

Goal: Build the typed region/effect model in shadow mode, without changing
accepted/rejected behavior.

#### ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.2.1 — Initial Region/Effect Inventory

Status: done

Goal: Add a read-only internal inventory for transaction control-flow regions
and child-activation effects covering existing shipped control-flow forms.

Acceptance:

- The inventory represents transaction body, `when`, `switch`, `while`,
  `until`, and `repeat` regions with entry/exit/backedge metadata.
- It records local `do`, generated `do`, `spawn`, `await_all`, and `await_any`
  effects without changing lowering behavior.
- Focused tests prove representative existing fixtures produce expected effect
  summaries and no accepted/rejected behavior changes.
- Unsupported combinations remain rejected by existing validators.
- No generated HDL or schedule-report public schema changes unless explicitly
  documented as private/test-only diagnostics.

### ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.3 — Effect-Aware Safety Checks

Status: done

Goal: Add invariant checks over the shadow effect graph while still preserving
current behavior.

Acceptance:

- The checker can prove current accepted repeat/spawn/do/await shapes satisfy
  restart-before-drain and loop-backedge dominance.
- The checker can explain current fail-closed shapes as missing proofs rather
  than missing syntax allow-list entries.

### ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.4 — Child Discovery And Generated Instance Planning

Status: done

Goal: Derive child-action discovery, local start/done wiring requirements, and
generated-child instance planning from effects instead of parallel ad hoc walks.

Acceptance:

- Existing local child wiring and generated-child summaries remain unchanged.
- Deterministic instance names stay stable for all shipped fixtures.
- Shadow/planned outputs detect any divergence before validators are migrated.

### ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.5 — Outstanding-Child Lifetime Contract

Status: done

Goal: Move outstanding-child lifetime rules into the effect checker.

Acceptance:

- `spawn`, `await_any`, and `await_all` effects distinguish observe vs drain.
- Repeat and loop backedges reject live outstanding children unless a later leaf
  adds an explicit lifetime rule.
- Current same-body drain paths continue to pass.

### ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.6 — Domain, Binding, And CDC Effects

Status: done

Goal: Model binding handoffs, domain ownership, and CDC activation requirements
as explicit effects.

Acceptance:

- Same-domain, cross-domain, binding, and generated-top requirements are
  explicit in the effect model.
- Existing CDC and binding diagnostics remain stable until migrated.
- No implicit CDC or binding inference is introduced.

### ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.7 — Validator Migration

Status: active

Goal: Replace syntax-path allow-list decisions with region/effect proof
decisions incrementally.

Acceptance:

- Each migration leaf removes or neutralizes one hardcoded combination gate only
  after the effect checker proves the six invariants.
- Existing positive and negative fixtures stay behaviorally stable except for
  the intentionally selected newly accepted combinations.

#### ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.7.1 — Cross-Domain Activation Coverage Gate

Status: done

Goal: Route the transaction-domain validator decision that permits a covered
cross-domain blocking `(do child)` through the effect checker proof instead of
a direct crossing lookup.

Acceptance:

- The same-domain validator skips its failure only when
  `ControlFlowEffects` proves `activation_crossing_covers_child_start` for the
  caller/child pair.
- Existing covered cross-domain blocking `do` fixtures still lower.
- Existing uncovered cross-domain `do`, cross-domain `spawn`, and deeper
  placement diagnostics stay stable.
- No new cross-domain activation shape is accepted in this leaf.

#### ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.7.2 — Next Validator Gate Selection

Status: done

Goal: Select and migrate the next narrow validator gate that can be proven by
the current region/effect model without broad behavior widening.

Acceptance:

- The selected gate has positive and negative fixtures before migration.
- The effect checker already exposes the proof or violation needed for the
  decision, or the leaf first adds that proof in shadow mode.
- Public diagnostics and accepted/rejected behavior remain stable unless the
  leaf explicitly selects one newly accepted combination.

Result:

- Selected the direct child-target same-domain validator check for `do` and
  `spawn` clauses.
- The validator now skips that direct target-domain check only when
  `ControlFlowEffects` proves `activation_target_is_same_domain`.
- Activation-domain metadata remains checked independently, so mismatched
  `(domain ...)` metadata and uncovered cross-domain activations keep their
  previous public diagnostics.
- The effect-check cache now rejects stale `refaddr` slots unless the cached
  weak actor reference still identifies the live actor.

#### ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.7.3 — Next Validator Gate Selection

Status: done

Goal: Select and migrate the next narrow validator gate after same-domain
target validation, still preserving public behavior unless one exact
combination is explicitly selected for widening.

Acceptance:

- The selected gate has positive and negative fixtures before migration.
- The region/effect checker owns the proof or violation used by the migrated
  decision.
- Existing accepted/rejected behavior remains stable unless this leaf records
  an exact newly accepted combination before implementation.

Result:

- Selected the activation-instance `(domain NAME)` metadata validator check for
  `do` and `spawn` clauses.
- The validator now skips the direct metadata-domain comparison only when
  `ControlFlowEffects` proves `activation_domain_is_explicit` for the same
  transaction, child, and authored domain.
- A proof for one authored domain does not hide a mismatched metadata site for
  the same child; mismatches keep their existing public diagnostic.

#### ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.7.4 — Next Validator Gate Selection

Status: done

Goal: Select and migrate the next narrow validator gate after activation-domain
metadata validation, still preserving public behavior unless one exact
combination is explicitly selected for widening.

Acceptance:

- The selected gate has positive and negative fixtures before migration.
- The region/effect checker owns the proof or violation used by the migrated
  decision.
- Existing accepted/rejected behavior remains stable unless this leaf records
  an exact newly accepted combination before implementation.

Result:

- Selected activation binding endpoint domain validation for simple input and
  output actor endpoints.
- The effect checker now emits `binding_endpoint_is_same_domain` proofs and
  `binding_endpoint_domain_mismatch` violations in addition to typed binding
  handoff proofs.
- The public validator skips the direct binding endpoint domain walk only for
  those same-domain endpoint proofs; expression bindings and cross-domain
  endpoints retain the previous validator behavior and diagnostics.

#### ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.7.5 — Next Validator Gate Selection

Status: active

Goal: Select and migrate the next narrow validator gate after binding endpoint
domain validation, still preserving public behavior unless one exact
combination is explicitly selected for widening.

Acceptance:

- The selected gate has positive and negative fixtures before migration.
- The region/effect checker owns the proof or violation used by the migrated
  decision.
- Existing accepted/rejected behavior remains stable unless this leaf records
  an exact newly accepted combination before implementation.

### ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8 — Combination Enablement

Status: pending

Goal: Use the migrated checker to accept broader combinations by construction.

Acceptance:

- New accepted combinations are selected from the backlog only after the effect
  model proves safety.
- Book/spec examples describe the general rule, not a growing list of special
  cases.

### ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.9 — Public Contract And Documentation Simplification

Status: pending

Goal: Convert user-facing docs from enumerated combination lists to
construction rules once the architecture supports it.

Acceptance:

- mdBook explains the compositional rule and the remaining explicit limits.
- Support matrix, spec, audits, and knowledge cards reflect the new contract.

## Verification Log

- 2026-06-10 (`.1`): architecture task owner created; ADR `0013`,
  `docs/TASK_TREE.md`, `docs/decisions/INDEX.md`, and `MEMORY.md` point at the
  shadow-mode first implementation leaf; implementation not started yet.
  `scripts/check_memory_architecture.sh`,
  `knowledge-map/scripts/check_knowledge_map.sh`, `prove -Iperl
  t/1414-docs-relative-paths-audit.t`, and `git diff --check` pass.
- 2026-06-10 (`.2.1`): added private
  `FSM::Scheduler::ISF::ControlFlowEffects` shadow inventory for typed
  transaction/`when`/`switch`/`while`/`until`/`repeat` regions, local/generated
  child starts, spawn starts, `await_any` observe effects, `await_all` drain
  effects, outstanding children at region exits, binding/domain metadata, and
  deterministic generated-child instance names. It is not wired into lowering
  or public reports, so accepted/rejected behavior is unchanged. `perl -Iperl
  -c perl/FSM/Scheduler/ISF/ControlFlowEffects.pm`; `perl -Iperl -c
  t/1419-isf-control-flow-effect-inventory.t`; `prove -Iperl
  t/1419-isf-control-flow-effect-inventory.t`; `prove -Iperl
  t/1379-isf-loop-contained-repeat-body-local-do.t
  t/1383-isf-loop-and-deeper-repeat-body-spawn.t
  t/1384-isf-loop-and-deeper-repeat-body-multi-pending-awaitany.t
  t/1388-isf-when-body-local-do.t
  t/1419-isf-control-flow-effect-inventory.t`; `prove -Iperl
  t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf
  --no-book` (Files=294, Tests=2133); `knowledge-map/scripts/check_knowledge_map.sh`;
  `scripts/check_memory_architecture.sh`; `prove -Iperl
  t/1414-docs-relative-paths-audit.t`; `mdbook build docs/book`; and
  `git diff --check` pass.
- 2026-06-10 (`.5`): refined the private lifetime checker so live
  outstanding children on loop/repeat backedges report
  `backedge_has_live_outstanding_children`, while live children at non-loop
  exits report `region_exit_has_live_outstanding_children`. Added explicit
  `await_any` lifetime proofs for single-pending completion and multi-pending
  later-drain obligations. Public lowering/diagnostics remain unchanged.
  `perl -Iperl -c perl/FSM/Scheduler/ISF/ControlFlowEffects.pm`; `perl
  -Iperl -c t/1423-isf-control-flow-lifetime-checks.t`; `prove -Iperl
  t/1421-isf-control-flow-effect-checks.t
  t/1423-isf-control-flow-lifetime-checks.t`; `prove -Iperl
  t/1419-isf-control-flow-effect-inventory.t
  t/1421-isf-control-flow-effect-checks.t
  t/1422-isf-control-flow-child-plan.t
  t/1423-isf-control-flow-lifetime-checks.t`; `prove -Iperl
  t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf
  --no-book` (Files=294, Tests=2133); `knowledge-map/scripts/check_knowledge_map.sh`;
  `scripts/check_memory_architecture.sh`; `prove -Iperl
  t/1414-docs-relative-paths-audit.t`; `mdbook build docs/book`; and
  `git diff --check` pass.
- 2026-06-10 (`.6`): enriched private child-start effects with actor
  domain context, caller/child/activation domain contracts, typed binding
  handoff direction/timing, generated-top start/done and binding requirements,
  and explicit activation-crossing CDC start/done requirements. The checker now
  proves same-domain activations, covered cross-domain blocking `do`, binding
  handoffs, and generated-top/CDC requirements, while uncovered cross-domain
  `do` and cross-domain `spawn` remain private violations that mirror the
  existing fail-closed validators. No lowering or public report path consumes
  the model yet. `perl -Iperl -c
  perl/FSM/Scheduler/ISF/ControlFlowEffects.pm`; `perl -Iperl -c
  t/1424-isf-control-flow-domain-binding-effects.t`; `prove -Iperl
  t/1424-isf-control-flow-domain-binding-effects.t`; `prove -Iperl
  t/1419-isf-control-flow-effect-inventory.t
  t/1421-isf-control-flow-effect-checks.t
  t/1422-isf-control-flow-child-plan.t
  t/1423-isf-control-flow-lifetime-checks.t
  t/1424-isf-control-flow-domain-binding-effects.t`; `prove -Iperl
  t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf
  --no-book` (Files=294, Tests=2133); `scripts/check_memory_architecture.sh`;
  `knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl
  t/1414-docs-relative-paths-audit.t`; `mdbook build docs/book`; and
  `git diff --check` pass.
- 2026-06-10 (`.7.1`): migrated the transaction-domain validator decision for
  covered cross-domain blocking `do` from a direct activation-crossing lookup
  to the `ControlFlowEffects` proof
  `activation_crossing_covers_child_start`. The existing activation-crossing
  placement gate remains in force, so uncovered `do`, cross-domain `spawn`,
  and deeper unsupported placements keep their prior diagnostics; no new
  source shape is accepted. `perl -Iperl -c
  perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c
  t/1425-isf-control-flow-validator-effect-migration.t`; `prove -Iperl
  t/1425-isf-control-flow-validator-effect-migration.t`; `prove -Iperl
  t/1247-isf-clock-domain-partition.t
  t/1387-isf-cross-domain-activation-handshake-lowering.t
  t/1425-isf-control-flow-validator-effect-migration.t`; `prove -Iperl
  t/1215-isf-spawn-parameter-binding.t`; `prove -Iperl
  t/1419-isf-control-flow-effect-inventory.t
  t/1421-isf-control-flow-effect-checks.t
  t/1422-isf-control-flow-child-plan.t
  t/1423-isf-control-flow-lifetime-checks.t
  t/1424-isf-control-flow-domain-binding-effects.t
  t/1425-isf-control-flow-validator-effect-migration.t`; `prove -Iperl
  t/1250-isf-spec-focused-test-index-audit.t`; and `./bin/ci-regression isf
  --no-book` (Files=294, Tests=2133); `scripts/check_memory_architecture.sh`;
  `knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl
  t/1414-docs-relative-paths-audit.t`; `mdbook build docs/book`; and
  `git diff --check` pass.
- 2026-06-10 (`.7.2`): migrated the same-domain child-target validator
  decision for `do`/`spawn` clauses from a direct domain comparison to the
  `ControlFlowEffects` proof `activation_target_is_same_domain`. Activation
  instance-domain metadata remains separately checked, so mismatched
  `(domain ...)` annotations and uncovered cross-domain activations keep their
  previous diagnostics. A focused negative test also caught and fixed a stale
  `refaddr` effect-check cache hazard by requiring the cached weak actor
  reference to still identify the live actor. `perl -Iperl -c
  perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c
  t/1426-isf-control-flow-same-domain-validator-effect-migration.t`; `prove
  -Iperl t/1247-isf-clock-domain-partition.t
  t/1387-isf-cross-domain-activation-handshake-lowering.t
  t/1425-isf-control-flow-validator-effect-migration.t
  t/1426-isf-control-flow-same-domain-validator-effect-migration.t`; `prove
  -Iperl t/1215-isf-spawn-parameter-binding.t`; `prove -Iperl
  t/1419-isf-control-flow-effect-inventory.t
  t/1421-isf-control-flow-effect-checks.t
  t/1422-isf-control-flow-child-plan.t
  t/1423-isf-control-flow-lifetime-checks.t
  t/1424-isf-control-flow-domain-binding-effects.t
  t/1425-isf-control-flow-validator-effect-migration.t
  t/1426-isf-control-flow-same-domain-validator-effect-migration.t`; `prove
  -Iperl t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression
  isf --no-book` (Files=294, Tests=2133); `scripts/check_memory_architecture.sh`;
  `knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl
  t/1414-docs-relative-paths-audit.t`; `mdbook build docs/book`; and
  `git diff --check` pass.
- 2026-06-10 (`.7.3`): migrated the activation-instance domain metadata
  validator decision for `do`/`spawn` clauses from a direct same-domain
  comparison to the `ControlFlowEffects` proof
  `activation_domain_is_explicit`, matched by transaction, child, and authored
  domain. Mismatched metadata still falls through to the existing public
  diagnostic, including when the same child has another good metadata proof.
  `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c
  t/1427-isf-control-flow-activation-domain-validator-effect-migration.t`;
  `prove -Iperl
  t/1427-isf-control-flow-activation-domain-validator-effect-migration.t`;
  `prove -Iperl t/1247-isf-clock-domain-partition.t
  t/1387-isf-cross-domain-activation-handshake-lowering.t
  t/1425-isf-control-flow-validator-effect-migration.t
  t/1426-isf-control-flow-same-domain-validator-effect-migration.t
  t/1427-isf-control-flow-activation-domain-validator-effect-migration.t`;
  `prove -Iperl t/1419-isf-control-flow-effect-inventory.t
  t/1421-isf-control-flow-effect-checks.t
  t/1422-isf-control-flow-child-plan.t
  t/1423-isf-control-flow-lifetime-checks.t
  t/1424-isf-control-flow-domain-binding-effects.t
  t/1425-isf-control-flow-validator-effect-migration.t
  t/1426-isf-control-flow-same-domain-validator-effect-migration.t
  t/1427-isf-control-flow-activation-domain-validator-effect-migration.t`;
  `prove -Iperl t/1215-isf-spawn-parameter-binding.t`; `prove -Iperl
  t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf
  --no-book` (Files=294, Tests=2133); `scripts/check_memory_architecture.sh`;
  `knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl
  t/1414-docs-relative-paths-audit.t`; `mdbook build docs/book`; and
  `git diff --check` pass.
- 2026-06-10 (`.7.4`): added binding endpoint-domain proofs and violations to
  `ControlFlowEffects`, then migrated activation binding endpoint validation
  to skip direct input/output binding domain walks only when the checker proves
  `binding_endpoint_is_same_domain` for the same transaction, child, role,
  child port, and actor endpoint. Cross-domain input/output bindings still
  fall through to the existing public read/write diagnostics, and expression
  bindings keep the existing recursive validator path. `perl -Iperl -c
  perl/FSM/Scheduler/ISF/ControlFlowEffects.pm`; `perl -Iperl -c
  perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c
  t/1428-isf-control-flow-binding-endpoint-validator-effect-migration.t`;
  `prove -Iperl
  t/1428-isf-control-flow-binding-endpoint-validator-effect-migration.t`;
  `prove -Iperl t/1247-isf-clock-domain-partition.t
  t/1387-isf-cross-domain-activation-handshake-lowering.t
  t/1425-isf-control-flow-validator-effect-migration.t
  t/1426-isf-control-flow-same-domain-validator-effect-migration.t
  t/1427-isf-control-flow-activation-domain-validator-effect-migration.t
  t/1428-isf-control-flow-binding-endpoint-validator-effect-migration.t`;
  `prove -Iperl t/1419-isf-control-flow-effect-inventory.t
  t/1421-isf-control-flow-effect-checks.t
  t/1422-isf-control-flow-child-plan.t
  t/1423-isf-control-flow-lifetime-checks.t
  t/1424-isf-control-flow-domain-binding-effects.t
  t/1425-isf-control-flow-validator-effect-migration.t
  t/1426-isf-control-flow-same-domain-validator-effect-migration.t
  t/1427-isf-control-flow-activation-domain-validator-effect-migration.t
  t/1428-isf-control-flow-binding-endpoint-validator-effect-migration.t`;
  `prove -Iperl t/1215-isf-spawn-parameter-binding.t`; `prove -Iperl
  t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf
  --no-book` (Files=294, Tests=2133); `scripts/check_memory_architecture.sh`;
  `knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl
  t/1414-docs-relative-paths-audit.t`; `mdbook build docs/book`; and
  `git diff --check` pass.
- 2026-06-10 (`.4`): added private `plan_actor` / `plan_inventory` child-plan
  projection derived from the shadow effect list. The plan records local child
  start/done wiring requirements, generated child instance plans, and sync
  points, and focused tests compare that private plan against current emitted
  `.fsm` / `_top` artifacts for local `do`, generated conditional `do`, repeat
  generated `do`, and spawn fan-out. No emitted artifact path consumes the plan
  yet. `perl -Iperl -c perl/FSM/Scheduler/ISF/ControlFlowEffects.pm`; `perl
  -Iperl -c t/1422-isf-control-flow-child-plan.t`; `prove -Iperl
  t/1422-isf-control-flow-child-plan.t`; `prove -Iperl
  t/1419-isf-control-flow-effect-inventory.t
  t/1421-isf-control-flow-effect-checks.t
  t/1422-isf-control-flow-child-plan.t`; `prove -Iperl
  t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf
  --no-book` (Files=294, Tests=2133); `knowledge-map/scripts/check_knowledge_map.sh`;
  `scripts/check_memory_architecture.sh`; `prove -Iperl
  t/1414-docs-relative-paths-audit.t`; `mdbook build docs/book`; and
  `git diff --check` pass.
- 2026-06-10 (`.3`): added private `check_actor` / `check_inventory`
  invariant checks over the shadow control-flow/effect inventory. The checker
  returns structured proofs and violations for outstanding-child lifetime,
  loop/repeat backedge dominance, `await_any` observe-not-drain semantics,
  `await_all` drain proofs, blocking-`do` done drains, deterministic generated
  instance identity, and explicit activation-domain metadata, without wiring
  the checker into lowering or public reports. `perl -Iperl -c
  perl/FSM/Scheduler/ISF/ControlFlowEffects.pm`; `perl -Iperl -c
  t/1421-isf-control-flow-effect-checks.t`; `prove -Iperl
  t/1421-isf-control-flow-effect-checks.t`; `prove -Iperl
  t/1419-isf-control-flow-effect-inventory.t
  t/1421-isf-control-flow-effect-checks.t`; `prove -Iperl
  t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf
  --no-book` (Files=294, Tests=2133); `knowledge-map/scripts/check_knowledge_map.sh`;
  `scripts/check_memory_architecture.sh`; `prove -Iperl
  t/1414-docs-relative-paths-audit.t`; `mdbook build docs/book`; and
  `git diff --check` pass.

## Commit Log

- `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.1`: `2a3f71e6`
  `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.1: own uniform activation architecture`.
- `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.2.1`: `4f6cde86`
  `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.2.1: add shadow effect inventory`.
- `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.3`: `b06197e4`
  `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.3: add shadow invariant checks`.
- `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.4`: `00a9e859`
  `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.4: derive child plan from effects`.
- `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.5`: `3cfd6cc5`
  `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.5: refine lifetime proofs`.
- `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.6`: `1d61afc7`
  `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.6: model domain binding cdc effects`.
- `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.7.1`: `d392930d`,
  `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.7.1: route xdomain do through effects`.
- `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.7.2`: `002a79d8`,
  `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.7.2: route same-domain activations through effects`.
- `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.7.3`: `a849e1fd`,
  `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.7.3: route activation domains through effects`.
- `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.7.4`: this commit,
  `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.7.4: route binding endpoints through effects`.
