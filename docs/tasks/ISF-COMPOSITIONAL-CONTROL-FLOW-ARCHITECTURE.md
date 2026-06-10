# ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE

Status: active

Roadmap lane: R14 / ISF compositional control-flow and activation architecture

Created: 2026-06-10

Current frontier: `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.5`

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

Status: active

Goal: Move outstanding-child lifetime rules into the effect checker.

Acceptance:

- `spawn`, `await_any`, and `await_all` effects distinguish observe vs drain.
- Repeat and loop backedges reject live outstanding children unless a later leaf
  adds an explicit lifetime rule.
- Current same-body drain paths continue to pass.

### ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.6 — Domain, Binding, And CDC Effects

Status: pending

Goal: Model binding handoffs, domain ownership, and CDC activation requirements
as explicit effects.

Acceptance:

- Same-domain, cross-domain, binding, and generated-top requirements are
  explicit in the effect model.
- Existing CDC and binding diagnostics remain stable until migrated.
- No implicit CDC or binding inference is introduced.

### ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.7 — Validator Migration

Status: pending

Goal: Replace syntax-path allow-list decisions with region/effect proof
decisions incrementally.

Acceptance:

- Each migration leaf removes or neutralizes one hardcoded combination gate only
  after the effect checker proves the six invariants.
- Existing positive and negative fixtures stay behaviorally stable except for
  the intentionally selected newly accepted combinations.

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
- `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.4`: this commit,
  `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.4: derive child plan from effects`.
