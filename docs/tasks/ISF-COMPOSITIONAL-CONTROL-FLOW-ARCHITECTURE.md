# ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE

Status: active

Roadmap lane: R14 / ISF compositional control-flow and activation architecture

Created: 2026-06-10

Current frontier: `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.25`

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

Status: done

Goal: Select and migrate the next narrow validator gate after binding endpoint
domain validation, still preserving public behavior unless one exact
combination is explicitly selected for widening.

Acceptance:

- The selected gate has positive and negative fixtures before migration.
- The region/effect checker owns the proof or violation used by the migrated
  decision.
- Existing accepted/rejected behavior remains stable unless this leaf records
  an exact newly accepted combination before implementation.

Result:

- Selected recursive input binding expression endpoint validation.
- The effect checker now records known actor-signal endpoints inside input
  binding list expressions, proving
  `binding_expression_endpoints_are_same_domain` or reporting
  `binding_expression_endpoint_domain_mismatch`.
- The public validator skips the recursive input binding expression read walk
  only for the all-same-domain proof; literals, unknowns, and mixed-domain
  expressions keep the previous validator behavior and diagnostics.

#### ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.7.6 — Next Validator Gate Selection

Status: done

Goal: Select and migrate the next narrow validator gate after input binding
expression endpoint validation, still preserving public behavior unless one
exact combination is explicitly selected for widening.

Acceptance:

- The selected gate has positive and negative fixtures before migration.
- The region/effect checker owns the proof or violation used by the migrated
  decision.
- Existing accepted/rejected behavior remains stable unless this leaf records
  an exact newly accepted combination before implementation.

Result:

- Selected rule-trigger target domain validation for local transaction triggers.
- The effect checker now inventories rule trigger effects, proving
  `rule_trigger_target_is_same_domain` or reporting
  `rule_trigger_target_domain_mismatch`.
- The public rule validator skips its direct target-domain comparison only for
  the same-domain proof; cross-domain rule triggers keep their previous public
  clock-domain diagnostic.

#### ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.7.7 — Next Validator Gate Selection

Status: done

Goal: Select and migrate the next narrow validator gate after rule-trigger
target domain validation, still preserving public behavior unless one exact
combination is explicitly selected for widening.

Acceptance:

- The selected gate has positive and negative fixtures before migration.
- The region/effect checker owns the proof or violation used by the migrated
  decision.
- Existing accepted/rejected behavior remains stable unless this leaf records
  an exact newly accepted combination before implementation.

Result:

- Selected rule-trigger binding endpoint and input-expression domain
  validation after rule-trigger target domain validation.
- The effect checker now inventories rule-trigger binding handoffs, including
  generated trigger instances, and proves same-domain binding endpoints or
  input-expression endpoints at rule scope.
- The public rule validator skips its direct binding domain walk only for those
  same-domain rule-trigger binding proofs. Cross-domain rule-trigger input
  expressions and generated output bindings keep their previous public
  clock-domain diagnostics; direct/local rule-trigger output bindings remain
  fail-closed.

### ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8 — Combination Enablement

Status: active

Goal: Use the migrated checker to accept broader combinations by construction.

Acceptance:

- New accepted combinations are selected from the backlog only after the effect
  model proves safety.
- Book/spec examples describe the general rule, not a growing list of special
  cases.

#### ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.1 — First Effect-Proven Combination Selection

Status: done

Goal: Select the first narrow behavior-widening combination that can be accepted
by construction through the migrated region/effect checker.

Acceptance:

- The selected combination is named before implementation and has a clear
  backlog/user-facing source.
- The effect checker proves lifetime, activation target/domain, binding, CDC,
  generated-instance, and report/doc invariants for the selected shape before
  any public validator widening.
- Existing accepted/rejected behavior stays stable outside the named
  combination.
- mdBook, downstream spec, task tree, and Knowledge Map are updated if the
  selected combination changes public behavior.

Result:

- Selected the loop-contained repeat-body pending-spawn local blocking `do`
  shape:
  `(while cond (repeat n (spawn worker as w0) (do helper) (await_all done)))`.
- Source/backlog anchor: `ISF-SCHEDULING-BACKLOG-FRONTIER.4.1`, which asks for
  the first exact outstanding-child lifetime rule beyond one-off repeat
  re-entry drain gates, and the user-facing `13d`/backlog repeat-body
  child-activation sections that still limit broader outstanding-child
  sequencing.
- Current public behavior rejects the shape at the handcrafted
  `_validate_repeat_body_spawn_subset` pending-spawn `do` gate with:
  `repeat-body do cannot appear while repeat-body spawn clauses are pending`.
- The effect checker already proves the required invariants for the exact
  shape: no outstanding children at the repeat and loop backedges,
  same-domain activation targets for the generated spawn and local `do`,
  static generated-spawn instance identity and generated-top start/done
  handoff, local blocking-`do` done drain, and final `await_all` drain of the
  pending spawned child.

#### ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.2 — While-Contained Pending-Spawn Local Do

Status: done

Goal: Accept the selected loop-contained repeat-body sequence where a generated
`spawn` remains pending across a local blocking `do`, then a same-body
`await_all` drains the spawned child before repeat and loop re-entry.

Acceptance:

- The public validator permits only the selected same-domain shape when
  `ControlFlowEffects` proves the repeat/loop backedges have no outstanding
  children, the generated spawn has deterministic top wiring, the local
  blocking `do` drains its own child, and the later `await_all` drains the
  pending spawn.
- Existing accepted loop-contained repeat-body spawn and local-do fixtures
  remain accepted.
- Missing final drain, multi-pending `await_any` without later drain,
  generated `do` while pending in this loop-contained shape, cross-domain
  activation, and unrelated deeper nesting remain fail-closed with stable or
  sharper diagnostics.
- The mdBook, downstream integration spec, live ISF spec/indexes, task tree,
  and Knowledge Map are updated for the new public behavior.

Result:

- Shipped the selected while-contained subset:
  `(while cond (repeat n (spawn worker as w0) (do helper) (await_all done)))`.
- The validator now permits that pending-spawn local blocking `do` only when
  `ControlFlowEffects` proves the exact repeat region has no live children at
  the repeat and `while` backedges, the spawned instance has static
  generated-top start/done handoff wiring, the local `do` drains its own child,
  and the final `await_all` drains the spawned instance.
- The `until` analogue, multi-pending spawned children across the local `do`,
  generated `do`, and post-`do` `await_any` remain fail-closed.
- User-facing docs, downstream handoff, live spec index, and the Knowledge Map
  fact card were synced for the new public behavior.

#### ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.3 — Next Effect-Proven Combination Selection

Status: done

Goal: Select the next narrow behavior-widening combination that can be accepted
by construction through the migrated region/effect checker after the
while-contained pending-spawn local-`do` slice.

Acceptance:

- The selected combination is named before implementation and has a clear
  backlog/user-facing source.
- The effect checker proves lifetime, activation target/domain, binding, CDC,
  generated-instance, and report/doc invariants for the selected shape before
  any public validator widening.
- Existing accepted/rejected behavior stays stable outside the named
  combination.
- mdBook, downstream spec, task tree, and Knowledge Map are updated if the
  selected combination changes public behavior.

Result:

- Selected the until-contained repeat-body pending-spawn local blocking `do`
  analogue:
  `(until cond (repeat n (spawn worker as w0) (do helper) (await_all done)))`.
- Source/backlog anchor: the `.8.2` public behavior intentionally left the
  matching `until` shape deferred, and
  `ISF-SCHEDULING-BACKLOG-FRONTIER.4.1` asks for exact outstanding-child
  lifetime rules beyond one-off repeat re-entry drain gates.
- Current public behavior rejects the shape at the existing handcrafted
  `_validate_repeat_body_spawn_subset` pending-spawn `do` gate with:
  `repeat-body do cannot appear while repeat-body spawn clauses are pending`.
- The effect checker already proves the required invariants for the exact
  shape: no outstanding children at the repeat and `until` backedges,
  same-domain activation targets for the generated spawn and local `do`,
  static generated-spawn instance identity and generated-top start/done
  handoff, local blocking-`do` done drain, and final `await_all` drain of the
  pending spawned child.

#### ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.4 — Until-Contained Pending-Spawn Local Do

Status: done

Goal: Accept the selected until-contained repeat-body sequence where a
generated `spawn` remains pending across a local blocking `do`, then a
same-body `await_all` drains the spawned child before repeat and `until`
re-entry.

Acceptance:

- The public validator permits only the selected same-domain `until` shape when
  `ControlFlowEffects` proves the repeat/loop backedges have no outstanding
  children, the generated spawn has deterministic top wiring, the local
  blocking `do` drains its own child, and the later `await_all` drains the
  pending spawn.
- Existing accepted loop-contained repeat-body spawn, local-do, and the
  while-contained pending-spawn local-`do` fixtures remain accepted.
- Missing final drain, multi-pending spawned children across the local `do`,
  generated `do` while pending in this loop-contained shape, cross-domain
  activation, post-`do` `await_any`, and unrelated deeper nesting remain
  fail-closed with stable or sharper diagnostics.
- The mdBook, downstream integration spec, live ISF spec/indexes, task tree,
  and Knowledge Map are updated for the new public behavior.

Result:

- Shipped the selected until-contained subset:
  `(until cond (repeat n (spawn worker as w0) (do helper) (await_all done)))`.
- The validator now permits the loop-contained pending-spawn local blocking
  `do` proof for both `while` and `until`, but only when `ControlFlowEffects`
  proves the exact loop kind's re-test backedge, the nested repeat backedge,
  the static generated-spawn handoff, the local `do` drain, and the final
  `await_all` drain.
- Missing final drain, post-`do` `await_any`, multi-pending spawned children
  across the local `do`, generated `do`, and unrelated deeper nesting remain
  fail-closed.
- User-facing docs, downstream handoff, live spec index, and the Knowledge Map
  fact card were synced for the new public behavior.

#### ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.5 — Next Effect-Proven Combination Selection

Status: done

Goal: Select the next narrow behavior-widening combination that can be accepted
by construction through the migrated region/effect checker after the
loop-contained pending-spawn local-`do` slices.

Acceptance:

- The selected combination is named before implementation and has a clear
  backlog/user-facing source.
- The effect checker proves lifetime, activation target/domain, binding, CDC,
  generated-instance, and report/doc invariants for the selected shape before
  any public validator widening.
- Existing accepted/rejected behavior stays stable outside the named
  combination.
- mdBook, downstream spec, task tree, and Knowledge Map are updated if the
  selected combination changes public behavior.

Result:

- Selected the while-contained repeat-body pending-spawn local blocking `do`
  shape that uses single-pending post-`do` `await_any` as the final sync:
  `(while cond (repeat n (spawn worker as w0) (do helper) (await_any done)))`.
- Source/backlog anchor: the `.8.4` public behavior intentionally leaves
  post-`do` `await_any` fail-closed in the loop-contained pending-spawn
  local-`do` family, and `ISF-SCHEDULING-BACKLOG-FRONTIER.4.1` asks for exact
  outstanding-child lifetime rules beyond one-off repeat re-entry drain gates.
- Current public behavior rejects the shape at the existing handcrafted
  `_validate_repeat_body_spawn_subset` pending-spawn `do` gate with:
  `repeat-body do cannot appear while repeat-body spawn clauses are pending`.
- The effect checker already proves the required invariants for the exact
  shape: no outstanding children at the repeat and `while` backedges,
  same-domain activation targets for the generated spawn and local `do`,
  static generated-spawn instance identity and generated-top start/done
  handoff, local blocking-`do` done drain, and
  `await_any_single_pending_completes_outstanding_set` for `w0_done`.

#### ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.6 — While-Contained Pending-Spawn Local Do Single-Pending AwaitAny

Status: done

Goal: Accept the selected while-contained repeat-body sequence where a
generated `spawn` remains pending across a local blocking `do`, then a
same-body single-pending `await_any` observes that spawned child before repeat
and `while` re-entry.

Acceptance:

- The public validator permits only the selected same-domain `while` shape when
  `ControlFlowEffects` proves the repeat/loop backedges have no outstanding
  children, the generated spawn has deterministic top wiring, the local
  blocking `do` drains its own child, and the later `await_any` has exactly one
  outstanding spawned child and completes that outstanding set.
- Existing accepted loop-contained `await_all` pending-spawn local-`do`
  fixtures remain accepted.
- Multi-pending post-`do` `await_any`, missing final sync, generated `do` while
  pending, cross-domain activation, the `until` analogue, and unrelated deeper
  nesting remain fail-closed with stable or sharper diagnostics.
- The mdBook, downstream integration spec, live ISF spec/indexes, task tree,
  and Knowledge Map are updated for the new public behavior.

Result:

- Shipped the selected while-contained subset:
  `(while cond (repeat n (spawn worker as w0) (do helper) (await_any done)))`.
- The validator now permits post-`do` `await_any` in this loop-contained
  pending-spawn local-`do` family only for the selected while-contained
  single-pending shape, when `ControlFlowEffects` proves
  `await_any_single_pending_completes_outstanding_set` for the spawned done
  port.
- The matching `until` post-`do` `await_any`, multi-pending post-`do`
  `await_any`, missing final sync, generated `do`, and unrelated deeper
  nesting remain fail-closed.
- User-facing docs, downstream handoff, live spec index, and the Knowledge Map
  fact card were synced for the new public behavior.

#### ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.7 — Next Effect-Proven Combination Selection

Status: done

Goal: Select the next narrow behavior-widening combination that can be accepted
by construction through the migrated region/effect checker after the
while-contained single-pending post-`do` `await_any` slice.

Acceptance:

- The selected combination is named before implementation and has a clear
  backlog/user-facing source.
- The effect checker proves lifetime, activation target/domain, binding, CDC,
  generated-instance, and report/doc invariants for the selected shape before
  any public validator widening.
- Existing accepted/rejected behavior stays stable outside the named
  combination.
- mdBook, downstream spec, task tree, and Knowledge Map are updated if the
  selected combination changes public behavior.

Result:

- Selected the next implementation slice:
  `(while cond (repeat n (spawn worker as w0) (spawn worker as w1) (do helper) (await_all done)))`.
- The source/backlog anchor is the current `.8.6` public behavior and focused
  tests, which still reject the multi-pending loop-contained pending-spawn
  local-`do` family at the existing pending-spawn `do` gate.
- A read-only effect-checker probe proves the selected shape has clean `while`
  and `repeat` backedges, static generated-spawn instances `w0`/`w1`,
  generated-top start/done handoff requirements for `w0_done`/`w1_done`,
  same-domain activation targets for both spawns and `helper`, a blocking
  `do` drain for `helper_done`, and an `await_all` drain for
  `w0_done,w1_done`.
- The `until` twin also probes effect-clean, but the next implementation leaf
  selects only the `while` shape so public behavior widens by one narrow
  combination first.

#### ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.8 — While-Contained Multi-Pending Pending-Spawn Local Do AwaitAll

Status: done

Goal: Accept the selected while-contained repeat-body sequence where two
generated `spawn` clauses remain pending across a local blocking `do`, then a
same-body `await_all` drains both spawned children before repeat and `while`
re-entry.

Acceptance:

- The public validator permits only the selected same-domain `while` shape when
  `ControlFlowEffects` proves clean repeat/`while` backedges, deterministic
  generated-top handoffs and static instances for all pending generated
  spawns, a local blocking-`do` done drain, and an `await_all` drain over the
  exact outstanding spawned done-port set.
- Existing accepted single-pending `while`/`until` pending-spawn local-`do`
  fixtures and the selected `.8.6` single-pending `await_any` fixture remain
  accepted.
- The `until` multi-pending analogue, post-`do` multi-pending `await_any`,
  missing final sync, generated `do`, cross-domain activation, and unrelated
  deeper nesting remain fail-closed.
- The mdBook, downstream integration spec, live ISF spec/indexes, task tree,
  and Knowledge Map are updated for the new public behavior.

Result:

- Shipped the selected while-contained two-spawn subset:
  `(while cond (repeat n (spawn worker as w0) (spawn worker as w1) (do helper) (await_all done)))`.
- The validator proof helper now accepts an exact pending-spawn set and permits
  this shape only when the effect checker proves generated-top handoffs,
  static generated instances, same-domain activation targets, a local
  blocking-`do` drain, an exact `await_all` drain for `w0_done,w1_done`, and
  clean repeat/`while` backedges.
- The `until` multi-pending analogue, post-`do` multi-pending `await_any`,
  missing final sync, generated `do`, cross-domain activation, and unrelated
  deeper nesting remain fail-closed.
- User-facing docs, downstream handoff, feature matrix, backlog, live spec, and
  the Knowledge Map fact card were synced for the new public behavior.

#### ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.9 — Next Effect-Proven Combination Selection

Status: done

Goal: Select the next narrow behavior-widening combination that can be accepted
by construction through the migrated region/effect checker after the
while-contained multi-pending pending-spawn local-`do` `await_all` slice.

Acceptance:

- The selected combination is named before implementation and has a clear
  backlog/user-facing source.
- The effect checker proves lifetime, activation target/domain, binding, CDC,
  generated-instance, and report/doc invariants for the selected shape before
  any public validator widening.
- Existing accepted/rejected behavior stays stable outside the named
  combination.
- mdBook, downstream spec, task tree, and Knowledge Map are updated if the
  selected combination changes public behavior.

Result:

- Selected the next implementation slice:
  `(until cond (repeat n (spawn worker as w0) (spawn worker as w1) (do helper) (await_all done)))`.
- The source/backlog anchor is the `.8.8` public behavior, which accepts the
  corresponding `while` two-spawn `await_all` shape but still rejects the
  `until` twin at the existing pending-spawn `do` gate.
- A read-only effect-checker probe proves the selected `until` shape has clean
  `until` and `repeat` backedges, static generated-spawn instances `w0`/`w1`,
  generated-top start/done handoff requirements for `w0_done`/`w1_done`,
  same-domain activation targets for both spawns and `helper`, a blocking
  `do` drain for `helper_done`, and an `await_all` drain for
  `w0_done,w1_done`.
- The post-`do` `await_any` variants, generated `do`, cross-domain activation,
  and unrelated deeper nesting remain outside the selected next implementation
  leaf.

#### ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.10 — Until-Contained Multi-Pending Pending-Spawn Local Do AwaitAll

Status: done

Goal: Accept the selected until-contained repeat-body sequence where two
generated `spawn` clauses remain pending across a local blocking `do`, then a
same-body `await_all` drains both spawned children before repeat and `until`
re-entry.

Acceptance:

- The public validator permits only the selected same-domain `until` shape when
  `ControlFlowEffects` proves clean repeat/`until` backedges, deterministic
  generated-top handoffs and static instances for all pending generated
  spawns, a local blocking-`do` done drain, and an `await_all` drain over the
  exact outstanding spawned done-port set.
- Existing accepted single-pending `while`/`until`, `.8.6` single-pending
  `await_any`, and `.8.8` while multi-pending pending-spawn local-`do`
  fixtures remain accepted.
- Post-`do` multi-pending `await_any`, missing final sync, generated `do`,
  cross-domain activation, and unrelated deeper nesting remain fail-closed.
- The mdBook, downstream integration spec, live ISF spec/indexes, task tree,
  and Knowledge Map are updated for the new public behavior.

Result:

- Shipped the selected until-contained two-spawn subset:
  `(until cond (repeat n (spawn worker as w0) (spawn worker as w1) (do helper) (await_all done)))`.
- The validator now permits the exact two-spawn pending-spawn local-`do`
  `await_all` shape for both loop kinds only when the effect checker proves
  generated-top handoffs, static generated instances, same-domain activation
  targets, a local blocking-`do` drain, an exact `await_all` drain for
  `w0_done,w1_done`, and clean repeat/loop backedges.
- Post-`do` multi-pending `await_any`, missing final sync, generated `do`,
  cross-domain activation, wider fan-out, and unrelated deeper nesting remain
  fail-closed.
- User-facing docs, downstream handoff, feature matrix, backlog, live spec, and
  the Knowledge Map fact card were synced for the new public behavior.

#### ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.11 — Next Effect-Proven Combination Selection

Status: done

Goal: Select the next narrow behavior-widening combination that can be accepted
by construction through the migrated region/effect checker after the
loop-contained multi-pending pending-spawn local-`do` `await_all` slices.

Acceptance:

- The selected combination is named before implementation and has a clear
  backlog/user-facing source.
- The effect checker proves lifetime, activation target/domain, binding, CDC,
  generated-instance, and report/doc invariants for the selected shape before
  any public validator widening.
- Existing accepted/rejected behavior stays stable outside the named
  combination.
- mdBook, downstream spec, task tree, and Knowledge Map are updated if the
  selected combination changes public behavior.

Result:

- Selected the next implementation slice:
  `(until cond (repeat n (spawn worker as w0) (do helper) (await_any done)))`.
- The source/backlog anchor is the shipped `.8.6` `while` single-pending
  post-`do` `await_any` behavior and the documented fail-closed `until` twin.
- A read-only effect-checker probe proves the selected `until` shape has clean
  `until` and `repeat` backedges, a static generated-spawn instance `w0`,
  generated-top start/done handoff requirements for `w0_done`, same-domain
  activation targets for the spawn and `helper`, a blocking `do` drain for
  `helper_done`, and
  `await_any_single_pending_completes_outstanding_set` for `w0_done`.
- Wider fan-out, generated `do`, cross-domain activation, post-`do`
  multi-pending `await_any`, missing final sync, and unrelated deeper nesting
  remain outside the selected next implementation leaf.

#### ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.12 — Until-Contained Pending-Spawn Local Do AwaitAny

Status: done

Goal: Accept the selected until-contained repeat-body sequence where one
generated `spawn` remains pending across a local blocking `do`, then a same-body
single-pending `await_any` observes that spawned child before repeat and `until`
re-entry.

Acceptance:

- The public validator permits only the selected same-domain `until` shape when
  `ControlFlowEffects` proves clean repeat/`until` backedges, deterministic
  generated-top handoffs and a static instance for the pending generated spawn,
  a local blocking-`do` done drain, and
  `await_any_single_pending_completes_outstanding_set` for the exact spawned
  done-port set.
- Existing accepted `while`/`until` `await_all`, `.8.6` `while`
  single-pending `await_any`, and `.8.8`/`.8.10` two-spawn `await_all` fixtures
  remain accepted.
- Wider fan-out, generated `do`, cross-domain activation, missing final sync,
  post-`do` multi-pending `await_any`, and unrelated deeper nesting remain
  fail-closed.
- The mdBook, downstream integration spec, live ISF spec/indexes, task tree,
  and Knowledge Map are updated for the new public behavior.

Result:

- Shipped the selected until-contained single-pending subset:
  `(until cond (repeat n (spawn worker as w0) (do helper) (await_any done)))`.
- The validator now permits the single-pending pending-spawn local-`do`
  `await_any` shape for both `while` and `until` only when the effect checker
  proves generated-top handoffs, static generated instances, same-domain
  activation targets, a local blocking-`do` drain, an exact
  `await_any_single_pending_completes_outstanding_set` proof for `w0_done`,
  and clean repeat/loop backedges.
- Wider fan-out, generated `do`, cross-domain activation, missing final sync,
  post-`do` multi-pending `await_any`, and unrelated deeper nesting remain
  fail-closed.
- User-facing docs, downstream handoff, feature matrix, backlog, live spec, and
  the Knowledge Map fact card were synced for the new public behavior.

#### ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.13 — Next Effect-Proven Combination Selection

Status: done

Goal: Select the next narrow behavior-widening combination that can be accepted
by construction through the migrated region/effect checker after the
loop-contained single-pending pending-spawn local-`do` `await_any` slices.

Acceptance:

- The selected combination is named before implementation and has a clear
  backlog/user-facing source.
- The effect checker proves lifetime, activation target/domain, binding, CDC,
  generated-instance, and report/doc invariants for the selected shape before
  any public validator widening.
- Existing accepted/rejected behavior stays stable outside the named
  combination.
- mdBook, downstream spec, task tree, and Knowledge Map are updated if the
  selected combination changes public behavior.

Result:

- Selected the next implementation slice:
  `(while cond (repeat n (spawn worker as w0) (spawn worker as w1) (spawn worker as w2) (do helper) (await_all done)))`.
- The source/backlog anchor is the shipped two-spawn `while`/`until`
  pending-spawn local-`do` `await_all` behavior and the documented
  fail-closed wider fan-out neighbor.
- A read-only effect-checker probe proves the selected `while` shape has clean
  `while` and `repeat` backedges, static generated-spawn instances
  `w0`/`w1`/`w2`, generated-top start/done handoff requirements for
  `w0_done`/`w1_done`/`w2_done`, same-domain activation targets for all spawns
  and `helper`, a blocking `do` drain for `helper_done`, and an `await_all`
  drain for `w0_done,w1_done,w2_done`.
- The `until` three-spawn analogue, generated `do`, cross-domain activation,
  post-`do` multi-pending `await_any`, missing final sync, wider fan-outs
  beyond three, and unrelated deeper nesting remain outside the selected next
  implementation leaf.

#### ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.14 — While-Contained Three-Pending Pending-Spawn Local Do AwaitAll

Status: done

Goal: Accept the selected while-contained repeat-body sequence where three
generated `spawn` clauses remain pending across a local blocking `do`, then a
same-body `await_all` drains all three spawned children before repeat and
`while` re-entry.

Acceptance:

- The public validator permits only the selected same-domain `while` shape when
  `ControlFlowEffects` proves clean repeat/`while` backedges, deterministic
  generated-top handoffs and static instances for all pending generated
  spawns, a local blocking-`do` done drain, and an `await_all` drain over the
  exact outstanding spawned done-port set.
- Existing accepted one- and two-spawn `while`/`until` local-`do` `await_all`
  fixtures plus single-pending `await_any` fixtures remain accepted.
- The `until` three-spawn analogue, generated `do`, cross-domain activation,
  missing final sync, post-`do` multi-pending `await_any`, wider fan-outs
  beyond three, and unrelated deeper nesting remain fail-closed.
- The mdBook, downstream integration spec, live ISF spec/indexes, task tree,
  and Knowledge Map are updated for the new public behavior.

Result:

- Shipped the selected while-contained three-spawn subset:
  `(while cond (repeat n (spawn worker as w0) (spawn worker as w1) (spawn worker as w2) (do helper) (await_all done)))`.
- The validator now permits exactly three pending generated spawns across one
  local blocking `do` for the selected `while` shape only when the effect
  checker proves generated-top handoffs, static generated instances,
  same-domain activation targets, a local blocking-`do` drain, an exact
  `await_all` drain for `w0_done,w1_done,w2_done`, and clean repeat/`while`
  backedges.
- The `until` three-spawn analogue, generated `do`, cross-domain activation,
  missing final sync, post-`do` multi-pending `await_any`, fan-outs beyond
  three, and unrelated deeper nesting remain fail-closed.
- User-facing docs, downstream handoff, feature matrix, backlog, live spec, and
  the Knowledge Map fact card were synced for the new public behavior.

#### ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.15 — Next Effect-Proven Combination Selection

Status: done

Goal: Select the next narrow behavior-widening combination that can be accepted
by construction through the migrated region/effect checker after the selected
while-contained three-spawn pending-spawn local-`do` `await_all` slice.

Acceptance:

- The selected combination is named before implementation and has a clear
  backlog/user-facing source.
- The effect checker proves lifetime, activation target/domain, binding, CDC,
  generated-instance, and report/doc invariants for the selected shape before
  any public validator widening.
- Existing accepted/rejected behavior stays stable outside the named
  combination.
- mdBook, downstream spec, task tree, and Knowledge Map are updated if the
  selected combination changes public behavior.

Result:

- Selected the next implementation slice:
  `(until cond (repeat n (spawn worker as w0) (spawn worker as w1) (spawn worker as w2) (do helper) (await_all done)))`.
- The source/backlog anchor is the shipped `.8.14` `while` three-spawn
  pending-spawn local-`do` `await_all` behavior and the documented
  fail-closed `until` twin.
- The focused effect-checker test proves the selected `until` shape has clean
  `until` and `repeat` backedges, static generated-spawn instances
  `w0`/`w1`/`w2`, generated-top start/done handoff requirements for
  `w0_done`/`w1_done`/`w2_done`, same-domain activation targets for all spawns
  and `helper`, a blocking `do` drain for `helper_done`, and an `await_all`
  drain for `w0_done,w1_done,w2_done`, while public lowering still rejects it.
- Generated `do`, cross-domain activation, post-`do` multi-pending
  `await_any`, missing final sync, fan-outs beyond three, and unrelated deeper
  nesting remain outside the selected next implementation leaf.

#### ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.16 — Until-Contained Three-Pending Pending-Spawn Local Do AwaitAll

Status: done

Goal: Accept the selected until-contained repeat-body sequence where three
generated `spawn` clauses remain pending across a local blocking `do`, then a
same-body `await_all` drains all three spawned children before repeat and
`until` re-entry.

Acceptance:

- The public validator permits only the selected same-domain `until` shape when
  `ControlFlowEffects` proves clean repeat/`until` backedges, deterministic
  generated-top handoffs and static instances for all pending generated
  spawns, a local blocking-`do` done drain, and an `await_all` drain over the
  exact outstanding spawned done-port set.
- Existing accepted one-, two-, and `.8.14` three-spawn `while` local-`do`
  `await_all` fixtures plus single-pending `await_any` fixtures remain
  accepted.
- Generated `do`, cross-domain activation, missing final sync, post-`do`
  multi-pending `await_any`, fan-outs beyond three, and unrelated deeper
  nesting remain fail-closed.
- The mdBook, downstream integration spec, live ISF spec/indexes, task tree,
  and Knowledge Map are updated for the new public behavior.

Result:

- Shipped the selected until-contained three-spawn subset:
  `(until cond (repeat n (spawn worker as w0) (spawn worker as w1) (spawn worker as w2) (do helper) (await_all done)))`.
- The validator now permits exactly three pending generated spawns across one
  local blocking `do` for both `while` and `until` only when the effect checker
  proves generated-top handoffs, static generated instances, same-domain
  activation targets, a local blocking-`do` drain, an exact `await_all` drain
  for `w0_done,w1_done,w2_done`, and clean repeat/loop backedges.
- Generated `do`, cross-domain activation, missing final sync, post-`do`
  multi-pending `await_any`, fan-outs beyond three, and unrelated deeper
  nesting remain fail-closed.
- User-facing docs, downstream handoff, feature matrix, backlog, live spec, and
  the Knowledge Map fact card were synced for the new public behavior.

#### ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.17 — Next Effect-Proven Combination Selection

Status: done

Goal: Select the next narrow behavior-widening combination that can be accepted
by construction through the migrated region/effect checker after the
loop-contained three-spawn pending-spawn local-`do` `await_all` slices.

Acceptance:

- The selected combination is named before implementation and has a clear
  backlog/user-facing source.
- The effect checker proves lifetime, activation target/domain, binding, CDC,
  generated-instance, and report/doc invariants for the selected shape before
  any public validator widening.
- Existing accepted/rejected behavior stays stable outside the named
  combination.
- mdBook, downstream spec, task tree, and Knowledge Map are updated if the
  selected combination changes public behavior.

Result:

- Selected the next implementation slice:
  `(while cond (repeat n (spawn worker as w0) (spawn worker as w1) (spawn worker as w2) (spawn worker as w3) (do helper) (await_all done)))`.
- The source/backlog anchor is the shipped `.8.16` three-spawn `while`/`until`
  pending-spawn local-`do` `await_all` behavior and the documented
  fail-closed "fan-outs beyond three" boundary in the mdBook / feature
  backlog.
- A read-only effect-checker probe proves the selected `while` shape has clean
  `while` and `repeat` backedges, static generated-spawn instances
  `w0`/`w1`/`w2`/`w3`, generated-top start/done handoff requirements for
  `w0_done`/`w1_done`/`w2_done`/`w3_done`, same-domain activation targets for
  all spawns and `helper`, a blocking `do` drain for `helper_done`, and an
  `await_all` drain for `w0_done,w1_done,w2_done,w3_done`; public lowering
  still rejects the source at the existing pending-spawn `do` gate before the
  implementation leaf.
- The `until` four-spawn analogue also probes effect-clean, and the
  multi-pending post-`do` `await_any` plus later `await_all` shape is also
  effect-clean, but both remain outside the selected next implementation leaf
  so public behavior widens by one exact combination first.

#### ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.18 — While-Contained Four-Pending Pending-Spawn Local Do AwaitAll

Status: done

Goal: Accept the selected while-contained repeat-body sequence where four
generated `spawn` clauses remain pending across a local blocking `do`, then a
same-body `await_all` drains all four spawned children before repeat and
`while` re-entry.

Acceptance:

- The public validator permits only the selected same-domain `while` shape when
  `ControlFlowEffects` proves clean repeat/`while` backedges, deterministic
  generated-top handoffs and static instances for all pending generated
  spawns, a local blocking-`do` done drain, and an `await_all` drain over the
  exact outstanding spawned done-port set.
- Existing accepted one-, two-, and three-spawn `while`/`until` local-`do`
  `await_all` fixtures plus single-pending `await_any` fixtures remain
  accepted.
- The `until` four-spawn analogue, generated `do`, cross-domain activation,
  missing final sync, post-`do` multi-pending `await_any`, fan-outs beyond
  four, and unrelated deeper nesting remain fail-closed.
- The mdBook, downstream integration spec, live ISF spec/indexes, task tree,
  and Knowledge Map are updated for the new public behavior.

Result:

- Public lowering now accepts the exact
  `(while cond (repeat n (spawn worker as w0) (spawn worker as w1) (spawn worker as w2) (spawn worker as w3) (do helper) (await_all done)))`
  shape when the migrated effect checker proves all four generated-spawn
  handoffs, the local `helper` drain, the exact four-child `await_all` drain,
  and clean `repeat`/`while` backedges.
- Focused tests cover the new accepted `while` four-spawn lowering path and
  lock the effect-clean `until` four-spawn analogue behind the public gate.
- Existing one-, two-, and three-spawn `while`/`until` local-`do` `await_all`
  fixtures and single-pending post-`do` `await_any` fixtures remain accepted.
- User-facing docs, downstream handoff specs, the support matrix, backlog, and
  the Knowledge Map fact card now state the one-sided four-spawn boundary:
  `while` four-spawn is shipped; `until` four-spawn, fan-outs beyond four,
  generated `do`, and multi-pending post-`do` `await_any` remain fail-closed.

#### ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.19 — Next Effect-Proven Combination Selection

Status: done

Goal: Select the next narrow behavior-widening combination that can be accepted
by construction through the migrated region/effect checker after the
while-contained four-spawn pending-spawn local-`do` `await_all` slice.

Acceptance:

- The selected combination is named before implementation and has a clear
  backlog/user-facing source.
- The effect checker proves lifetime, activation target/domain, binding, CDC,
  generated-instance, and report/doc invariants for the selected shape before
  any public validator widening.
- Existing accepted/rejected behavior stays stable outside the named
  combination.
- mdBook, downstream spec, task tree, and Knowledge Map are updated if the
  selected combination changes public behavior.

Result:

- Selected the body-first `until` twin of the just-shipped `.8.18` shape as
  the next implementation slice:
  `(until cond (repeat n (spawn worker as w0) (spawn worker as w1) (spawn worker as w2) (spawn worker as w3) (do helper) (await_all done)))`.
- The source/backlog anchor is the user-facing boundary added by `.8.18`:
  the mdBook, specs, backlog, and Knowledge Map all state that `while`
  four-spawn is shipped while the body-first `until` four-spawn twin remains
  deferred.
- Existing focused coverage in
  `t/1433-isf-until-pending-spawn-local-do-effect-widening.t` proves the
  selected `until` shape has clean `until` and `repeat` backedges, static
  generated-spawn instances `w0`/`w1`/`w2`/`w3`, generated-top start/done
  handoff requirements for all four instances, a local `helper` drain, and an
  `await_all` drain for `w0_done,w1_done,w2_done,w3_done`; public lowering
  still rejects the source at the pending-spawn `do` gate before the
  implementation leaf.
- Multi-pending post-`do` `await_any`, generated `do`, and fan-outs beyond
  four remain outside the selected next implementation leaf.

#### ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.20 — Until-Contained Four-Pending Pending-Spawn Local Do AwaitAll

Status: done

Goal: Accept the selected body-first `until` repeat-body sequence where four
generated `spawn` clauses remain pending across a local blocking `do`, then a
same-body `await_all` drains all four spawned children before repeat and
`until` re-entry.

Acceptance:

- The public validator permits only the selected same-domain `until` shape when
  `ControlFlowEffects` proves clean repeat/`until` backedges, deterministic
  generated-top handoffs and static instances for all pending generated
  spawns, a local blocking-`do` done drain, and an `await_all` drain over the
  exact outstanding spawned done-port set.
- Existing accepted one-, two-, three-, and `while` four-spawn local-`do`
  `await_all` fixtures plus single-pending `await_any` fixtures remain
  accepted.
- Generated `do`, cross-domain activation, missing final sync, post-`do`
  multi-pending `await_any`, fan-outs beyond four, and unrelated deeper
  nesting remain fail-closed.
- The mdBook, downstream integration spec, live ISF spec/indexes, task tree,
  and Knowledge Map are updated for the new public behavior.

Result:

- Public lowering now accepts the exact
  `(until cond (repeat n (spawn worker as w0) (spawn worker as w1) (spawn worker as w2) (spawn worker as w3) (do helper) (await_all done)))`
  shape when the migrated effect checker proves all four generated-spawn
  handoffs, the local `helper` drain, the exact four-child `await_all` drain,
  and clean `repeat`/`until` backedges.
- Focused tests now cover the accepted `until` four-spawn lowering path and
  add a five-spawn negative so fan-outs beyond four remain behind the public
  gate even when the private effect proof can drain all outstanding children.
- Existing one-, two-, three-, and `while` four-spawn local-`do` `await_all`
  fixtures and single-pending post-`do` `await_any` fixtures remain accepted.
- User-facing docs, downstream handoff specs, the support matrix, backlog, and
  the Knowledge Map fact card now state that two-, three-, and four-spawn
  local-`do` `await_all` fan-outs are shipped for both `while` and `until`;
  generated `do`, fan-outs beyond four, and multi-pending post-`do`
  `await_any` remain fail-closed.

#### ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.21 — Next Effect-Proven Combination Selection

Status: done

Goal: Select the next narrow behavior-widening combination that can be accepted
by construction through the migrated region/effect checker after the
`while`/`until` four-spawn pending-spawn local-`do` `await_all` slices.

Acceptance:

- The selected combination is named before implementation and has a clear
  backlog/user-facing source.
- The effect checker proves lifetime, activation target/domain, binding, CDC,
  generated-instance, and report/doc invariants for the selected shape before
  any public validator widening.
- Existing accepted/rejected behavior stays stable outside the named
  combination.
- mdBook, downstream spec, task tree, and Knowledge Map are updated if the
  selected combination changes public behavior.

Result:

- Selected the while-contained post-`do` multi-pending `await_any` observation
  plus later `await_all` drain as the next implementation slice:
  `(while cond (repeat n (spawn worker as w0) (spawn worker as w1) (do helper) (await_any done) (await_all done)))`.
- The source/backlog anchor is the still-public deferred
  "multi-pending post-`do` `await_any`" boundary in the mdBook, specs,
  backlog, and Knowledge Map after `.8.20`.
- A read-only effect-checker probe proves the selected `while` shape has clean
  `while` and `repeat` backedges, static generated-spawn instances `w0`/`w1`,
  generated-top start/done handoff requirements for `w0_done`/`w1_done`,
  same-domain activation targets for both spawns and `helper`, a local
  `helper` drain, `await_any_observes_without_full_drain` over
  `w0_done,w1_done`, `await_any_multi_pending_requires_later_drain`, and a
  later `await_all` drain for `w0_done,w1_done`; public lowering still rejects
  the source at the post-`do` multi-pending `await_any` gate before the
  implementation leaf.
- The matching body-first `until` shape, wider fan-outs, generated `do`, and
  missing later `await_all` remain outside the selected next implementation
  leaf.

#### ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.22 — While-Contained Post-Do Multi-Pending AwaitAny Then AwaitAll

Status: done

Goal: Accept the selected `while` repeat-body sequence where two generated
`spawn` clauses remain pending across a local blocking `do`, a post-`do`
multi-pending `await_any` observes one of the pending done pulses, and a later
same-body `await_all` drains the full outstanding set before repeat and
`while` re-entry.

Acceptance:

- The public validator permits only the selected same-domain `while` shape when
  `ControlFlowEffects` proves clean repeat/`while` backedges, deterministic
  generated-top handoffs and static instances for both pending generated
  spawns, a local blocking-`do` done drain, a post-`do` multi-pending
  `await_any` observation with a later-drain obligation, and an `await_all`
  drain over the exact outstanding spawned done-port set.
- Existing accepted one-, two-, three-, and four-spawn local-`do` `await_all`
  fixtures plus single-pending `await_any` fixtures remain accepted.
- The matching `until` post-`do` multi-pending `await_any`, generated `do`,
  cross-domain activation, missing final `await_all`, wider fan-outs, and
  unrelated deeper nesting remain fail-closed.
- The mdBook, downstream integration spec, live ISF spec/indexes, task tree,
  and Knowledge Map are updated for the new public behavior.

Result:

- Public lowering now accepts the exact
  `(while cond (repeat n (spawn worker as w0) (spawn worker as w1) (do helper) (await_any done) (await_all done)))`
  shape when the migrated effect checker proves both generated-spawn handoffs,
  the local `helper` drain, the post-`do` multi-pending `await_any` observation
  with a later-drain obligation, the exact two-child `await_all` drain, and
  clean `repeat`/`while` backedges.
- Focused tests now cover the accepted `while` post-`do` multi-pending
  `await_any` lowering path and lock the matching effect-clean `until` shape
  behind the public gate.
- Existing one-, two-, three-, and four-spawn local-`do` `await_all` fixtures
  and single-pending post-`do` `await_any` fixtures remain accepted.
- User-facing docs, downstream handoff specs, the support matrix, backlog, and
  the Knowledge Map fact card now state that the exact `while` two-spawn
  post-`do` multi-pending `await_any` plus later `await_all` shape is shipped;
  matching `until`, wider post-`do` multi-pending `await_any`, generated `do`,
  fan-outs beyond four, and missing later `await_all` remain fail-closed.

#### ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.23 — Next Effect-Proven Combination Selection

Status: done

Goal: Select the next narrow behavior-widening combination that can be accepted
by construction through the migrated region/effect checker after the
while-contained post-`do` multi-pending `await_any` plus later `await_all`
slice.

Acceptance:

- The selected combination is named before implementation and has a clear
  backlog/user-facing source.
- The effect checker proves lifetime, activation target/domain, binding, CDC,
  generated-instance, and report/doc invariants for the selected shape before
  any public validator widening.
- Existing accepted/rejected behavior stays stable outside the named
  combination.
- mdBook, downstream spec, task tree, and Knowledge Map are updated if the
  selected combination changes public behavior.

Result:

- Selected the matching body-first `until` post-`do` multi-pending
  `await_any` observation plus later `await_all` drain as the next
  implementation slice:
  `(until cond (repeat n (spawn worker as w0) (spawn worker as w1) (do helper) (await_any done) (await_all done)))`.
- The source/backlog anchor is the still-public deferred matching
  body-first `until` post-`do` multi-pending `await_any` boundary in the
  mdBook, specs, backlog, and Knowledge Map after `.8.22`.
- A read-only effect-checker probe proves the selected `until` shape has clean
  `until` and `repeat` backedges, static generated-spawn instances `w0`/`w1`,
  generated-top start/done handoff requirements for `w0_done`/`w1_done`,
  same-domain activation targets for both spawns and `helper`, a local
  `helper` drain, `await_any_observes_without_full_drain` over
  `w0_done,w1_done`, `await_any_multi_pending_requires_later_drain`, and a
  later `await_all` drain for `w0_done,w1_done`; public lowering still rejects
  the source at the post-`do` multi-pending `await_any` gate before the
  implementation leaf.
- Wider post-`do` multi-pending `await_any`, generated `do`, fan-outs beyond
  four, and missing later `await_all` remain outside the selected next
  implementation leaf.

#### ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.24 — Until-Contained Post-Do Multi-Pending AwaitAny Then AwaitAll

Status: done

Goal: Accept the selected body-first `until` repeat-body sequence where two
generated `spawn` clauses remain pending across a local blocking `do`, a
post-`do` multi-pending `await_any` observes one of the pending done pulses,
and a later same-body `await_all` drains the full outstanding set before
repeat and `until` re-entry.

Acceptance:

- The public validator permits only the selected same-domain `until` shape
  when `ControlFlowEffects` proves clean repeat/`until` backedges,
  deterministic generated-top handoffs and static instances for both pending
  generated spawns, a local blocking-`do` done drain, a post-`do`
  multi-pending `await_any` observation with a later-drain obligation, and an
  `await_all` drain over the exact outstanding spawned done-port set.
- Existing accepted one-, two-, three-, and four-spawn local-`do` `await_all`
  fixtures plus single-pending post-`do` `await_any` fixtures and the shipped
  `while` post-`do` multi-pending `await_any` fixture remain accepted.
- Generated `do`, cross-domain activation, missing final `await_all`, wider
  fan-outs, and unrelated deeper nesting remain fail-closed.
- The mdBook, downstream integration spec, live ISF spec/indexes, task tree,
  and Knowledge Map are updated for the new public behavior.

Result:

- Public lowering now accepts the exact
  `(until cond (repeat n (spawn worker as w0) (spawn worker as w1) (do helper) (await_any done) (await_all done)))`
  shape when the migrated effect checker proves both generated-spawn handoffs,
  the local `helper` drain, the post-`do` multi-pending `await_any` observation
  with a later-drain obligation, the exact two-child `await_all` drain, and
  clean `repeat`/`until` backedges.
- Focused tests now cover the accepted body-first `until` post-`do`
  multi-pending `await_any` lowering path, keep the previously shipped
  `while` path accepted, and lock a wider three-spawn `until` post-`do`
  multi-pending `await_any` shape behind the public gate.
- Existing one-, two-, three-, and four-spawn local-`do` `await_all` fixtures
  and single-pending post-`do` `await_any` fixtures remain accepted.
- User-facing docs, downstream handoff specs, the support matrix, backlog, and
  the Knowledge Map fact card now state that the exact `while` and body-first
  `until` two-spawn post-`do` multi-pending `await_any` plus later `await_all`
  shapes are shipped; generated `do`, wider post-`do` multi-pending
  `await_any`, fan-outs beyond four, and missing later `await_all` remain
  fail-closed.

#### ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.25 — Next Effect-Proven Combination Selection

Status: active

Goal: Select the next narrow behavior-widening combination that can be accepted
by construction through the migrated region/effect checker after the
`while`/`until` post-`do` multi-pending `await_any` plus later `await_all`
slices.

Acceptance:

- The selected combination is named before implementation and has a clear
  backlog/user-facing source.
- The effect checker proves lifetime, activation target/domain, binding, CDC,
  generated-instance, and report/doc invariants for the selected shape before
  any public validator widening.
- Existing accepted/rejected behavior stays stable outside the named
  combination.
- mdBook, downstream spec, task tree, and Knowledge Map are updated if the
  selected combination changes public behavior.

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
- 2026-06-10 (`.7.5`): added recursive actor-signal endpoint summaries for
  input binding list expressions and checker proof/violation codes
  `binding_expression_endpoints_are_same_domain` and
  `binding_expression_endpoint_domain_mismatch`. The validator now skips the
  recursive input-binding expression read walk only when the checker proves the
  whole expression's known signal endpoints are same-domain; mixed-domain
  expressions still fall through to the existing public read diagnostic.
  `perl -Iperl -c perl/FSM/Scheduler/ISF/ControlFlowEffects.pm`; `perl
  -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c
  t/1429-isf-control-flow-binding-expression-validator-effect-migration.t`;
  `prove -Iperl
  t/1429-isf-control-flow-binding-expression-validator-effect-migration.t`;
  `prove -Iperl t/1241-isf-transaction-port-bindings.t
  t/1247-isf-clock-domain-partition.t
  t/1387-isf-cross-domain-activation-handshake-lowering.t
  t/1425-isf-control-flow-validator-effect-migration.t
  t/1426-isf-control-flow-same-domain-validator-effect-migration.t
  t/1427-isf-control-flow-activation-domain-validator-effect-migration.t
  t/1428-isf-control-flow-binding-endpoint-validator-effect-migration.t
  t/1429-isf-control-flow-binding-expression-validator-effect-migration.t`;
  `prove -Iperl t/1419-isf-control-flow-effect-inventory.t
  t/1421-isf-control-flow-effect-checks.t
  t/1422-isf-control-flow-child-plan.t
  t/1423-isf-control-flow-lifetime-checks.t
  t/1424-isf-control-flow-domain-binding-effects.t
  t/1425-isf-control-flow-validator-effect-migration.t
  t/1426-isf-control-flow-same-domain-validator-effect-migration.t
  t/1427-isf-control-flow-activation-domain-validator-effect-migration.t
  t/1428-isf-control-flow-binding-endpoint-validator-effect-migration.t
  t/1429-isf-control-flow-binding-expression-validator-effect-migration.t`;
  `prove -Iperl t/1215-isf-spawn-parameter-binding.t`; `prove -Iperl
  t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf
  --no-book` (Files=294, Tests=2133); `scripts/check_memory_architecture.sh`;
  `knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl
  t/1414-docs-relative-paths-audit.t`; `mdbook build docs/book`; and
  `git diff --check` pass.
- 2026-06-11 (`.7.7`): added rule-trigger binding handoffs to
  `ControlFlowEffects`, including generated rule-trigger instance identity for
  parameterized/defaulted generated triggers. The public rule validator now
  skips rule-trigger binding endpoint and input-expression domain walks only
  when the checker proves the same-domain binding at rule scope. Cross-domain
  rule-trigger input expressions and generated output bindings keep their
  previous public clock-domain diagnostics; direct/local rule-trigger output
  bindings remain fail-closed. `perl -Iperl -c
  perl/FSM/Scheduler/ISF/ControlFlowEffects.pm`; `perl -Iperl -c
  perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c
  t/1431-isf-control-flow-rule-trigger-binding-validator-effect-migration.t`;
  `prove -Iperl
  t/1431-isf-control-flow-rule-trigger-binding-validator-effect-migration.t
  t/1430-isf-control-flow-rule-trigger-validator-effect-migration.t
  t/1428-isf-control-flow-binding-endpoint-validator-effect-migration.t
  t/1429-isf-control-flow-binding-expression-validator-effect-migration.t`;
  `prove -Iperl t/1241-isf-transaction-port-bindings.t
  t/1242-isf-port-binding-conflict-semantics.t
  t/1243-isf-port-binding-schedule-report.t
  t/1248-isf-rule-trigger-parameter-binding.t
  t/1431-isf-control-flow-rule-trigger-binding-validator-effect-migration.t`;
  `prove -Iperl t/1419-isf-control-flow-effect-inventory.t
  t/1421-isf-control-flow-effect-checks.t
  t/1422-isf-control-flow-child-plan.t
  t/1423-isf-control-flow-lifetime-checks.t
  t/1424-isf-control-flow-domain-binding-effects.t
  t/1425-isf-control-flow-validator-effect-migration.t
  t/1426-isf-control-flow-same-domain-validator-effect-migration.t
  t/1427-isf-control-flow-activation-domain-validator-effect-migration.t
  t/1428-isf-control-flow-binding-endpoint-validator-effect-migration.t
  t/1429-isf-control-flow-binding-expression-validator-effect-migration.t
  t/1430-isf-control-flow-rule-trigger-validator-effect-migration.t
  t/1431-isf-control-flow-rule-trigger-binding-validator-effect-migration.t`;
  `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t`; and rerun
  `./bin/ci-regression isf --no-book` pass (Files=294, Tests=2133) after the
  first broad run identified the intentionally added `t/1431...` test needed
  the `docs/ISF_SPEC.md` focused-test index entry. `knowledge-map/scripts/check_knowledge_map.sh`;
  `scripts/check_memory_architecture.sh`; `prove -Iperl
  t/1414-docs-relative-paths-audit.t`; `mdbook build docs/book`; and
  `git diff --check` pass.
- 2026-06-11 (`.8.1`): selected
  `while -> repeat -> spawn -> local blocking do -> await_all` as the first
  behavior-widening combination to accept by construction. A probe of the
  exact actor showed current lowering rejects at the old pending-spawn `do`
  gate, while `ControlFlowEffects` returns no violations and proves both
  backedges have no outstanding children, the generated spawn has static
  generated-top wiring, the local blocking `do` drains its child, and the
  final `await_all` drains the pending spawn. `scripts/check_memory_architecture.sh`;
  `knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl
  t/1414-docs-relative-paths-audit.t`; and `git diff --check` pass.
- 2026-06-11 (`.8.2`): accepted the selected while-contained repeat-body
  pending-spawn local blocking `do` shape through the effect checker. The
  public validator permits the sequence only for one pending generated spawn
  followed by one plain local `do` and a same-body `await_all` drain proven by
  `ControlFlowEffects`; `until`, multi-pending, generated-do, and post-do
  `await_any` analogues remain fail-closed. `perl -Iperl -c
  perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c
  t/1432-isf-loop-pending-spawn-local-do-effect-widening.t`; `prove -Iperl
  t/1432-isf-loop-pending-spawn-local-do-effect-widening.t
  t/1379-isf-loop-contained-repeat-body-local-do.t
  t/1383-isf-loop-and-deeper-repeat-body-spawn.t
  t/1384-isf-loop-and-deeper-repeat-body-multi-pending-awaitany.t
  t/1423-isf-control-flow-lifetime-checks.t`; and `prove -Iperl
  t/1250-isf-spec-focused-test-index-audit.t
  t/1305-isf-book-feature-matrix-audit.t
  t/1307-isf-loop-body-doc-truth-audit.t` pass. `prove -Iperl
  t/1419-isf-control-flow-effect-inventory.t
  t/1421-isf-control-flow-effect-checks.t
  t/1422-isf-control-flow-child-plan.t
  t/1423-isf-control-flow-lifetime-checks.t
  t/1424-isf-control-flow-domain-binding-effects.t
  t/1425-isf-control-flow-validator-effect-migration.t
  t/1426-isf-control-flow-same-domain-validator-effect-migration.t
  t/1427-isf-control-flow-activation-domain-validator-effect-migration.t
  t/1428-isf-control-flow-binding-endpoint-validator-effect-migration.t
  t/1429-isf-control-flow-binding-expression-validator-effect-migration.t
  t/1430-isf-control-flow-rule-trigger-validator-effect-migration.t
  t/1431-isf-control-flow-rule-trigger-binding-validator-effect-migration.t
  t/1432-isf-loop-pending-spawn-local-do-effect-widening.t`; `prove -Iperl
  t/1215-isf-spawn-parameter-binding.t
  t/1255-isf-schedule-report-golden-matrix.t`; `prove -Iperl
  t/1245-isf-transaction-loop-lowering.t`; `scripts/check_memory_architecture.sh`;
  `knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl
  t/1414-docs-relative-paths-audit.t`; `mdbook build docs/book`; `git diff
  --check`; and `./bin/ci-regression isf --no-book` (Files=294, Tests=2133)
  pass.
- 2026-06-11 (`.8.3`): selected the until-contained analogue of the `.8.2`
  behavior widening:
  `(until cond (repeat n (spawn worker as w0) (do helper) (await_all done)))`.
  A read-only probe confirmed `ControlFlowEffects` already emits
  `backedge_has_no_outstanding_children` for `until_retest` and
  `repeat_check_nonzero`, same-domain activation proofs for the spawn and
  local `do`, static generated instance / generated-top start-done handoff
  proofs for `w0`, a local blocking-`do` drain proof for `helper`, and an
  `await_all_drains_outstanding_children` proof for `w0_done`; public lowering
  still rejects the source at the existing pending-spawn `do` gate before the
  implementation leaf. `scripts/check_memory_architecture.sh`;
  `knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl
  t/1414-docs-relative-paths-audit.t`; and `git diff --check` pass.
- 2026-06-11 (`.8.4`): accepted the selected until-contained repeat-body
  pending-spawn local blocking `do` shape through the effect checker. The
  public validator now parameterizes the `.8.2` proof helper by loop kind and
  permits the exact single-pending-spawn local `do` + same-body `await_all`
  drain subset for `while` and `until`; missing final drain, post-`do`
  `await_any`, multi-pending spawned children across the local `do`, generated
  `do`, and unrelated deeper nesting remain fail-closed. `perl -Iperl -c
  perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c
  t/1432-isf-loop-pending-spawn-local-do-effect-widening.t`; `perl -Iperl -c
  t/1433-isf-until-pending-spawn-local-do-effect-widening.t`; `prove -Iperl
  t/1432-isf-loop-pending-spawn-local-do-effect-widening.t
  t/1433-isf-until-pending-spawn-local-do-effect-widening.t`; `prove -Iperl
  t/1432-isf-loop-pending-spawn-local-do-effect-widening.t
  t/1433-isf-until-pending-spawn-local-do-effect-widening.t
  t/1379-isf-loop-contained-repeat-body-local-do.t
  t/1383-isf-loop-and-deeper-repeat-body-spawn.t
  t/1384-isf-loop-and-deeper-repeat-body-multi-pending-awaitany.t
  t/1423-isf-control-flow-lifetime-checks.t`; `prove -Iperl
  t/1250-isf-spec-focused-test-index-audit.t
  t/1305-isf-book-feature-matrix-audit.t
  t/1307-isf-loop-body-doc-truth-audit.t`; `prove -Iperl
  t/1376-isf-book-example-lowering-audit.t`; `prove -Iperl
  t/1377-book-fsm-example-generation-audit.t`; `prove -Iperl
  t/1419-isf-control-flow-effect-inventory.t
  t/1421-isf-control-flow-effect-checks.t
  t/1422-isf-control-flow-child-plan.t
  t/1423-isf-control-flow-lifetime-checks.t
  t/1424-isf-control-flow-domain-binding-effects.t
  t/1425-isf-control-flow-validator-effect-migration.t
  t/1426-isf-control-flow-same-domain-validator-effect-migration.t
  t/1427-isf-control-flow-activation-domain-validator-effect-migration.t
  t/1428-isf-control-flow-binding-endpoint-validator-effect-migration.t
  t/1429-isf-control-flow-binding-expression-validator-effect-migration.t
  t/1430-isf-control-flow-rule-trigger-validator-effect-migration.t
  t/1431-isf-control-flow-rule-trigger-binding-validator-effect-migration.t
  t/1432-isf-loop-pending-spawn-local-do-effect-widening.t
  t/1433-isf-until-pending-spawn-local-do-effect-widening.t`;
  `scripts/check_memory_architecture.sh`;
  `knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl
  t/1414-docs-relative-paths-audit.t`; `mdbook build docs/book`; `git diff
  --check`; and `./bin/ci-regression isf --no-book` (Files=294, Tests=2133)
  pass.
- 2026-06-11 (`.8.5`): selected the while-contained single-pending post-`do`
  `await_any` analogue:
  `(while cond (repeat n (spawn worker as w0) (do helper) (await_any done)))`.
  A read-only probe confirmed `ControlFlowEffects` already emits
  `backedge_has_no_outstanding_children` for `while_retest` and
  `repeat_check_nonzero`, same-domain activation proofs for the spawn and
  local `do`, static generated instance / generated-top start-done handoff
  proofs for `w0`, a local blocking-`do` drain proof for `helper`, and
  `await_any_single_pending_completes_outstanding_set` for `w0_done`; public
  lowering still rejects the source at the existing pending-spawn `do` gate
  before the implementation leaf. The same probe confirmed the broader
  multi-pending post-`do` local-`do` shape is also effect-clean but is not the
  selected `.8.6` slice. `scripts/check_memory_architecture.sh`;
  `knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl
  t/1414-docs-relative-paths-audit.t`; and `git diff --check` pass.
- 2026-06-11 (`.8.6`): accepted the selected while-contained repeat-body
  pending-spawn local blocking `do` shape with single-pending post-`do`
  `await_any` through the effect checker. The validator permits that sync only
  when `ControlFlowEffects` proves
  `await_any_single_pending_completes_outstanding_set`; the `until` analogue,
  multi-pending post-`do` `await_any`, missing final sync, generated `do`, and
  unrelated deeper nesting remain fail-closed. `perl -Iperl -c
  perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c
  t/1432-isf-loop-pending-spawn-local-do-effect-widening.t`; `perl -Iperl -c
  t/1434-isf-while-pending-spawn-local-do-awaitany-effect-widening.t`; `prove
  -Iperl t/1432-isf-loop-pending-spawn-local-do-effect-widening.t
  t/1433-isf-until-pending-spawn-local-do-effect-widening.t
  t/1434-isf-while-pending-spawn-local-do-awaitany-effect-widening.t`; `prove
  -Iperl t/1432-isf-loop-pending-spawn-local-do-effect-widening.t
  t/1433-isf-until-pending-spawn-local-do-effect-widening.t
  t/1434-isf-while-pending-spawn-local-do-awaitany-effect-widening.t
  t/1379-isf-loop-contained-repeat-body-local-do.t
  t/1383-isf-loop-and-deeper-repeat-body-spawn.t
  t/1384-isf-loop-and-deeper-repeat-body-multi-pending-awaitany.t
  t/1423-isf-control-flow-lifetime-checks.t`; `prove -Iperl
  t/1250-isf-spec-focused-test-index-audit.t
  t/1305-isf-book-feature-matrix-audit.t
  t/1307-isf-loop-body-doc-truth-audit.t`; `prove -Iperl
  t/1376-isf-book-example-lowering-audit.t`; `prove -Iperl
  t/1377-book-fsm-example-generation-audit.t`; `prove -Iperl
  t/1419-isf-control-flow-effect-inventory.t
  t/1421-isf-control-flow-effect-checks.t
  t/1422-isf-control-flow-child-plan.t
  t/1423-isf-control-flow-lifetime-checks.t
  t/1424-isf-control-flow-domain-binding-effects.t
  t/1425-isf-control-flow-validator-effect-migration.t
  t/1426-isf-control-flow-same-domain-validator-effect-migration.t
  t/1427-isf-control-flow-activation-domain-validator-effect-migration.t
  t/1428-isf-control-flow-binding-endpoint-validator-effect-migration.t
  t/1429-isf-control-flow-binding-expression-validator-effect-migration.t
  t/1430-isf-control-flow-rule-trigger-validator-effect-migration.t
  t/1431-isf-control-flow-rule-trigger-binding-validator-effect-migration.t
  t/1432-isf-loop-pending-spawn-local-do-effect-widening.t
  t/1433-isf-until-pending-spawn-local-do-effect-widening.t
  t/1434-isf-while-pending-spawn-local-do-awaitany-effect-widening.t`;
  `scripts/check_memory_architecture.sh`;
  `knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl
  t/1414-docs-relative-paths-audit.t`; `mdbook build docs/book`; `git diff
  --check`; and `./bin/ci-regression isf --no-book` (Files=294, Tests=2133)
  pass.
- 2026-06-11 (`.8.7`): selected the while-contained multi-pending pending-spawn
  local blocking `do` plus `await_all` combination for the next implementation
  leaf:
  `(while cond (repeat n (spawn worker as w0) (spawn worker as w1) (do helper) (await_all done)))`.
  A read-only effect-checker probe reports `ok=1`, `backedge_has_no_outstanding_children`
  for `while_retest` and `repeat_check_nonzero`,
  `generated_top_start_done_handoff_required` and
  `generated_child_instance_is_static` for `w0`/`w1`,
  `activation_target_is_same_domain` for both generated spawns and `helper`,
  `blocking_do_drains_child_done` for `helper_done`, and
  `await_all_drains_outstanding_children` for `w0_done,w1_done`. The `until`
  twin also probes effect-clean but remains outside the selected next
  implementation leaf. `scripts/check_memory_architecture.sh`;
  `knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl
  t/1414-docs-relative-paths-audit.t`; and `git diff --check` pass.
- 2026-06-11 (`.8.8`): accepted the selected while-contained two-spawn
  pending-spawn local blocking `do` plus same-body `await_all` shape through
  the effect checker. The validator now proves the exact pending-spawn set
  before allowing the local `do` gate: generated-top start/done handoffs and
  static instance proofs for `w0`/`w1`, same-domain activation proofs for both
  spawns and `helper`, a blocking-`do` drain for `helper_done`, an
  `await_all_drains_outstanding_children` proof for `w0_done,w1_done`, and
  clean repeat/`while` backedges. `perl -Iperl -c
  perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c
  t/1432-isf-loop-pending-spawn-local-do-effect-widening.t`; `perl -Iperl -c
  t/1434-isf-while-pending-spawn-local-do-awaitany-effect-widening.t`; `prove
  -Iperl t/1432-isf-loop-pending-spawn-local-do-effect-widening.t
  t/1433-isf-until-pending-spawn-local-do-effect-widening.t
  t/1434-isf-while-pending-spawn-local-do-awaitany-effect-widening.t`; `prove
  -Iperl t/1250-isf-spec-focused-test-index-audit.t
  t/1305-isf-book-feature-matrix-audit.t
  t/1307-isf-loop-body-doc-truth-audit.t`; `prove -Iperl
  t/1376-isf-book-example-lowering-audit.t`; `prove -Iperl
  t/1377-book-fsm-example-generation-audit.t`; `prove -Iperl
  t/1419-isf-control-flow-effect-inventory.t
  t/1421-isf-control-flow-effect-checks.t
  t/1422-isf-control-flow-child-plan.t
  t/1423-isf-control-flow-lifetime-checks.t
  t/1424-isf-control-flow-domain-binding-effects.t
  t/1425-isf-control-flow-validator-effect-migration.t
  t/1426-isf-control-flow-same-domain-validator-effect-migration.t
  t/1427-isf-control-flow-activation-domain-validator-effect-migration.t
  t/1428-isf-control-flow-binding-endpoint-validator-effect-migration.t
  t/1429-isf-control-flow-binding-expression-validator-effect-migration.t
  t/1430-isf-control-flow-rule-trigger-validator-effect-migration.t
  t/1431-isf-control-flow-rule-trigger-binding-validator-effect-migration.t
  t/1432-isf-loop-pending-spawn-local-do-effect-widening.t
  t/1433-isf-until-pending-spawn-local-do-effect-widening.t
  t/1434-isf-while-pending-spawn-local-do-awaitany-effect-widening.t`;
  `scripts/check_memory_architecture.sh`;
  `knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl
  t/1414-docs-relative-paths-audit.t`; `mdbook build docs/book`; `git diff
  --check`; and `./bin/ci-regression isf --no-book` (Files=294, Tests=2133)
  pass.
- 2026-06-11 (`.8.9`): selected the until-contained two-spawn pending-spawn
  local blocking `do` plus same-body `await_all` combination for the next
  implementation leaf:
  `(until cond (repeat n (spawn worker as w0) (spawn worker as w1) (do helper) (await_all done)))`.
  A read-only effect-checker probe reports `effect_ok=1`,
  `backedge_has_no_outstanding_children` for `until_retest` and
  `repeat_check_nonzero`, `generated_top_start_done_handoff_required` and
  `generated_child_instance_is_static` for `w0`/`w1`,
  `activation_target_is_same_domain` for both generated spawns and `helper`,
  `blocking_do_drains_child_done` for `helper_done`, and
  `await_all_drains_outstanding_children` for `w0_done,w1_done`; public
  lowering still rejects the source at the existing pending-spawn `do` gate
  before the implementation leaf. `scripts/check_memory_architecture.sh`;
  `knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl
  t/1414-docs-relative-paths-audit.t`; and `git diff --check` pass.
- 2026-06-11 (`.8.10`): accepted the selected until-contained two-spawn
  pending-spawn local blocking `do` plus same-body `await_all` shape through
  the effect checker. The validator now permits the exact two-spawn
  pending-spawn local-`do` `await_all` shape for both `while` and `until`;
  wider fan-out, generated `do`, cross-domain activation, missing sync, and
  post-`do` multi-pending `await_any` remain fail-closed. `perl -Iperl -c
  perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c
  t/1433-isf-until-pending-spawn-local-do-effect-widening.t`; `prove -Iperl
  t/1432-isf-loop-pending-spawn-local-do-effect-widening.t
  t/1433-isf-until-pending-spawn-local-do-effect-widening.t
  t/1434-isf-while-pending-spawn-local-do-awaitany-effect-widening.t`; `prove
  -Iperl t/1250-isf-spec-focused-test-index-audit.t
  t/1305-isf-book-feature-matrix-audit.t
  t/1307-isf-loop-body-doc-truth-audit.t`; `prove -Iperl
  t/1376-isf-book-example-lowering-audit.t`; `prove -Iperl
  t/1377-book-fsm-example-generation-audit.t`; `prove -Iperl
  t/1419-isf-control-flow-effect-inventory.t
  t/1421-isf-control-flow-effect-checks.t
  t/1422-isf-control-flow-child-plan.t
  t/1423-isf-control-flow-lifetime-checks.t
  t/1424-isf-control-flow-domain-binding-effects.t
  t/1425-isf-control-flow-validator-effect-migration.t
  t/1426-isf-control-flow-same-domain-validator-effect-migration.t
  t/1427-isf-control-flow-activation-domain-validator-effect-migration.t
  t/1428-isf-control-flow-binding-endpoint-validator-effect-migration.t
  t/1429-isf-control-flow-binding-expression-validator-effect-migration.t
  t/1430-isf-control-flow-rule-trigger-validator-effect-migration.t
  t/1431-isf-control-flow-rule-trigger-binding-validator-effect-migration.t
  t/1432-isf-loop-pending-spawn-local-do-effect-widening.t
  t/1433-isf-until-pending-spawn-local-do-effect-widening.t
  t/1434-isf-while-pending-spawn-local-do-awaitany-effect-widening.t`;
  `scripts/check_memory_architecture.sh`;
  `knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl
  t/1414-docs-relative-paths-audit.t`; `mdbook build docs/book`; `git diff
  --check`; and `./bin/ci-regression isf --no-book` (Files=294, Tests=2133)
  pass.
- 2026-06-11 (`.8.11`): selected the until-contained single-pending
  pending-spawn local-`do` post-`do` `await_any` subset as the next
  implementation leaf. A read-only `ControlFlowEffects` probe proves clean
  `until`/`repeat` backedges, static `w0` identity, local `helper` drain, and
  `await_any_single_pending_completes_outstanding_set` for `w0_done`; the
  current public test `prove -Iperl
  t/1434-isf-while-pending-spawn-local-do-awaitany-effect-widening.t` still
  confirms the `until` analogue is rejected before the `.8.12` widening.
  `scripts/check_memory_architecture.sh`,
  `knowledge-map/scripts/check_knowledge_map.sh`, `prove -Iperl
  t/1414-docs-relative-paths-audit.t`, and `git diff --check` pass.
- 2026-06-11 (`.8.12`): accepted the selected until-contained single-pending
  pending-spawn local blocking `do` plus same-body `await_any` shape through
  the effect checker. The validator now permits the single-pending
  pending-spawn local-`do` `await_any` shape for both `while` and `until`;
  wider fan-out, generated `do`, cross-domain activation, missing sync, and
  post-`do` multi-pending `await_any` remain fail-closed. `perl -Iperl -c
  perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c
  t/1434-isf-while-pending-spawn-local-do-awaitany-effect-widening.t`;
  `prove -Iperl t/1434-isf-while-pending-spawn-local-do-awaitany-effect-widening.t`;
  `perl -Iperl -c t/1433-isf-until-pending-spawn-local-do-effect-widening.t`;
  `prove -Iperl t/1432-isf-loop-pending-spawn-local-do-effect-widening.t
  t/1433-isf-until-pending-spawn-local-do-effect-widening.t
  t/1434-isf-while-pending-spawn-local-do-awaitany-effect-widening.t`; `prove
  -Iperl t/1250-isf-spec-focused-test-index-audit.t
  t/1305-isf-book-feature-matrix-audit.t
  t/1307-isf-loop-body-doc-truth-audit.t`; `prove -Iperl
  t/1376-isf-book-example-lowering-audit.t` (70 complete fixtures);
  `prove -Iperl t/1377-book-fsm-example-generation-audit.t`; `prove -Iperl
  t/1419-isf-control-flow-effect-inventory.t
  t/1421-isf-control-flow-effect-checks.t
  t/1422-isf-control-flow-child-plan.t
  t/1423-isf-control-flow-lifetime-checks.t
  t/1424-isf-control-flow-domain-binding-effects.t
  t/1425-isf-control-flow-validator-effect-migration.t
  t/1426-isf-control-flow-same-domain-validator-effect-migration.t
  t/1427-isf-control-flow-activation-domain-validator-effect-migration.t
  t/1428-isf-control-flow-binding-endpoint-validator-effect-migration.t
  t/1429-isf-control-flow-binding-expression-validator-effect-migration.t
  t/1430-isf-control-flow-rule-trigger-validator-effect-migration.t
  t/1431-isf-control-flow-rule-trigger-binding-validator-effect-migration.t
  t/1432-isf-loop-pending-spawn-local-do-effect-widening.t
  t/1433-isf-until-pending-spawn-local-do-effect-widening.t
  t/1434-isf-while-pending-spawn-local-do-awaitany-effect-widening.t`;
  `knowledge-map/scripts/check_knowledge_map.sh`; `mdbook build docs/book`;
  `./bin/ci-regression isf --no-book` (Files=294, Tests=2133);
  `scripts/check_memory_architecture.sh`; `prove -Iperl
  t/1414-docs-relative-paths-audit.t`; and `git diff --check` pass.
- 2026-06-11 (`.8.13`): selected the while-contained three-spawn
  pending-spawn local blocking `do` plus same-body `await_all` combination for
  the next implementation leaf:
  `(while cond (repeat n (spawn worker as w0) (spawn worker as w1) (spawn worker as w2) (do helper) (await_all done)))`.
  A read-only effect-checker probe proves clean `while`/`repeat` backedges,
  static `w0`/`w1`/`w2` identities, generated-top start/done handoff
  requirements for `w0_done`/`w1_done`/`w2_done`, a local `helper` drain, and
  an `await_all` drain for `w0_done,w1_done,w2_done`; public lowering still
  rejects the source at the existing pending-spawn `do` gate before the
  implementation leaf. `scripts/check_memory_architecture.sh`,
  `knowledge-map/scripts/check_knowledge_map.sh`, `prove -Iperl
  t/1414-docs-relative-paths-audit.t`, and `git diff --check` pass.
- 2026-06-11 (`.8.14`): accepted the selected while-contained three-spawn
  pending-spawn local blocking `do` plus same-body `await_all` shape through
  the effect checker. The validator now permits exactly three pending
  generated spawns across one local blocking `do` for `while`; the matching
  `until` three-spawn shape, fan-outs beyond three, generated `do`,
  cross-domain activation, missing sync, and post-`do` multi-pending
  `await_any` remain fail-closed. `perl -Iperl -c
  perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c
  t/1432-isf-loop-pending-spawn-local-do-effect-widening.t`; `perl -Iperl -c
  t/1433-isf-until-pending-spawn-local-do-effect-widening.t`; `prove -Iperl
  t/1432-isf-loop-pending-spawn-local-do-effect-widening.t
  t/1433-isf-until-pending-spawn-local-do-effect-widening.t
  t/1434-isf-while-pending-spawn-local-do-awaitany-effect-widening.t`; `prove
  -Iperl t/1250-isf-spec-focused-test-index-audit.t
  t/1305-isf-book-feature-matrix-audit.t
  t/1307-isf-loop-body-doc-truth-audit.t`; `prove -Iperl
  t/1376-isf-book-example-lowering-audit.t` (71 complete fixtures);
  `prove -Iperl t/1377-book-fsm-example-generation-audit.t`;
  `knowledge-map/scripts/check_knowledge_map.sh`; `mdbook build docs/book`;
  `prove -Iperl t/1419-isf-control-flow-effect-inventory.t
  t/1421-isf-control-flow-effect-checks.t
  t/1422-isf-control-flow-child-plan.t
  t/1423-isf-control-flow-lifetime-checks.t
  t/1424-isf-control-flow-domain-binding-effects.t
  t/1425-isf-control-flow-validator-effect-migration.t
  t/1426-isf-control-flow-same-domain-validator-effect-migration.t
  t/1427-isf-control-flow-activation-domain-validator-effect-migration.t
  t/1428-isf-control-flow-binding-endpoint-validator-effect-migration.t
  t/1429-isf-control-flow-binding-expression-validator-effect-migration.t
  t/1430-isf-control-flow-rule-trigger-validator-effect-migration.t
  t/1431-isf-control-flow-rule-trigger-binding-validator-effect-migration.t
  t/1432-isf-loop-pending-spawn-local-do-effect-widening.t
  t/1433-isf-until-pending-spawn-local-do-effect-widening.t
  t/1434-isf-while-pending-spawn-local-do-awaitany-effect-widening.t`;
  `./bin/ci-regression isf --no-book` (Files=294, Tests=2133);
  `scripts/check_memory_architecture.sh`,
  `knowledge-map/scripts/check_knowledge_map.sh`, `prove -Iperl
  t/1414-docs-relative-paths-audit.t`, and `git diff --check` pass.
- 2026-06-11 (`.8.15`): selected the until-contained three-spawn
  pending-spawn local blocking `do` plus same-body `await_all` combination for
  the next implementation leaf:
  `(until cond (repeat n (spawn worker as w0) (spawn worker as w1) (spawn worker as w2) (do helper) (await_all done)))`.
  The focused selection test proves the private effect checker can prove the
  shape and that public lowering still rejects it before the implementation
  leaf. `prove -Iperl
  t/1433-isf-until-pending-spawn-local-do-effect-widening.t`;
  `scripts/check_memory_architecture.sh`,
  `knowledge-map/scripts/check_knowledge_map.sh`, `prove -Iperl
  t/1414-docs-relative-paths-audit.t`, and `git diff --check` pass.
- 2026-06-11 (`.8.16`): accepted the selected until-contained three-spawn
  pending-spawn local blocking `do` plus same-body `await_all` shape through
  the effect checker. The validator now permits exactly three pending
  generated spawns across one local blocking `do` for both `while` and
  `until`; fan-outs beyond three, generated `do`, cross-domain activation,
  missing sync, and post-`do` multi-pending `await_any` remain fail-closed.
  `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c
  t/1433-isf-until-pending-spawn-local-do-effect-widening.t`; `prove -Iperl
  t/1432-isf-loop-pending-spawn-local-do-effect-widening.t
  t/1433-isf-until-pending-spawn-local-do-effect-widening.t
  t/1434-isf-while-pending-spawn-local-do-awaitany-effect-widening.t`; `prove
  -Iperl t/1250-isf-spec-focused-test-index-audit.t
  t/1305-isf-book-feature-matrix-audit.t
  t/1307-isf-loop-body-doc-truth-audit.t`; `prove -Iperl
  t/1376-isf-book-example-lowering-audit.t` (72 complete fixtures);
  `prove -Iperl t/1377-book-fsm-example-generation-audit.t`;
  `knowledge-map/scripts/check_knowledge_map.sh`; `mdbook build docs/book`;
  `prove -Iperl t/1419-isf-control-flow-effect-inventory.t
  t/1421-isf-control-flow-effect-checks.t
  t/1422-isf-control-flow-child-plan.t
  t/1423-isf-control-flow-lifetime-checks.t
  t/1424-isf-control-flow-domain-binding-effects.t
  t/1425-isf-control-flow-validator-effect-migration.t
  t/1426-isf-control-flow-same-domain-validator-effect-migration.t
  t/1427-isf-control-flow-activation-domain-validator-effect-migration.t
  t/1428-isf-control-flow-binding-endpoint-validator-effect-migration.t
  t/1429-isf-control-flow-binding-expression-validator-effect-migration.t
  t/1430-isf-control-flow-rule-trigger-validator-effect-migration.t
  t/1431-isf-control-flow-rule-trigger-binding-validator-effect-migration.t
  t/1432-isf-loop-pending-spawn-local-do-effect-widening.t
  t/1433-isf-until-pending-spawn-local-do-effect-widening.t
  t/1434-isf-while-pending-spawn-local-do-awaitany-effect-widening.t`;
  `./bin/ci-regression isf --no-book` (Files=294, Tests=2133);
  `scripts/check_memory_architecture.sh`,
  `knowledge-map/scripts/check_knowledge_map.sh`, `prove -Iperl
  t/1414-docs-relative-paths-audit.t`, and `git diff --check` pass.
- 2026-06-11 (`.8.17`): selected the while-contained four-spawn
  pending-spawn local blocking `do` plus same-body `await_all` combination for
  the next implementation leaf:
  `(while cond (repeat n (spawn worker as w0) (spawn worker as w1) (spawn worker as w2) (spawn worker as w3) (do helper) (await_all done)))`.
  A read-only `perl -Iperl` probe confirms the private effect checker proves
  clean `while`/`repeat` backedges, static `w0`/`w1`/`w2`/`w3` identities,
  generated-top start/done handoff requirements for all four instances, a
  local `helper` drain, and an `await_all` drain for
  `w0_done,w1_done,w2_done,w3_done`; public lowering still rejects it at the
  existing pending-spawn `do` gate before the implementation leaf.
  `scripts/check_memory_architecture.sh`,
  `knowledge-map/scripts/check_knowledge_map.sh`, `prove -Iperl
  t/1414-docs-relative-paths-audit.t`, and `git diff --check` pass.
- 2026-06-11 (`.8.18`): accepted the selected while-contained four-spawn
  pending-spawn local blocking `do` plus same-body `await_all` shape by
  widening only the public `while`/four-spawn selector that consumes the
  existing effect proof. Added focused coverage for the accepted `while`
  four-spawn path and the effect-clean but still rejected `until` four-spawn
  analogue. Synced the mdBook control-flow chapter, support matrix, backlog,
  live ISF spec, downstream integration spec, and Knowledge Map fact card to
  the new boundary. `perl -Iperl -c
  perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c
  t/1432-isf-loop-pending-spawn-local-do-effect-widening.t`; `perl -Iperl -c
  t/1433-isf-until-pending-spawn-local-do-effect-widening.t`; `prove -Iperl
  t/1432-isf-loop-pending-spawn-local-do-effect-widening.t
  t/1433-isf-until-pending-spawn-local-do-effect-widening.t
  t/1434-isf-while-pending-spawn-local-do-awaitany-effect-widening.t`;
  `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t
  t/1305-isf-book-feature-matrix-audit.t
  t/1307-isf-loop-body-doc-truth-audit.t`; `prove -Iperl
  t/1376-isf-book-example-lowering-audit.t
  t/1377-book-fsm-example-generation-audit.t`; `prove -Iperl
  t/1419-isf-control-flow-effect-inventory.t
  t/1421-isf-control-flow-effect-checks.t
  t/1424-isf-control-flow-domain-binding-effects.t
  t/1425-isf-control-flow-validator-effect-migration.t
  t/1426-isf-control-flow-same-domain-validator-effect-migration.t
  t/1427-isf-control-flow-activation-domain-validator-effect-migration.t
  t/1428-isf-control-flow-binding-endpoint-validator-effect-migration.t
  t/1429-isf-control-flow-binding-expression-validator-effect-migration.t
  t/1430-isf-control-flow-rule-trigger-validator-effect-migration.t
  t/1431-isf-control-flow-rule-trigger-binding-validator-effect-migration.t
  t/1432-isf-loop-pending-spawn-local-do-effect-widening.t
  t/1433-isf-until-pending-spawn-local-do-effect-widening.t
  t/1434-isf-while-pending-spawn-local-do-awaitany-effect-widening.t`;
  `knowledge-map/scripts/check_knowledge_map.sh`;
  `scripts/check_memory_architecture.sh`; `prove -Iperl
  t/1414-docs-relative-paths-audit.t`; `mdbook build docs/book`; `git diff
  --check`; and `./bin/ci-regression isf --no-book` (Files=294, Tests=2133)
  pass.
- 2026-06-11 (`.8.19`): selected the body-first `until` four-spawn
  pending-spawn local blocking `do` plus same-body `await_all` combination for
  the next implementation leaf:
  `(until cond (repeat n (spawn worker as w0) (spawn worker as w1) (spawn worker as w2) (spawn worker as w3) (do helper) (await_all done)))`.
  The existing focused `until` coverage proves clean `until`/`repeat`
  backedges, static `w0`/`w1`/`w2`/`w3` identities, generated-top start/done
  handoff requirements for all four instances, a local `helper` drain, and an
  `await_all` drain for `w0_done,w1_done,w2_done,w3_done`; public lowering
  still rejects it at the pending-spawn `do` gate before the implementation
  leaf. `prove -Iperl
  t/1433-isf-until-pending-spawn-local-do-effect-widening.t`,
  `scripts/check_memory_architecture.sh`,
  `knowledge-map/scripts/check_knowledge_map.sh`, `prove -Iperl
  t/1414-docs-relative-paths-audit.t`, and `git diff --check` pass.
- 2026-06-11 (`.8.20`): accepted the selected body-first `until` four-spawn
  pending-spawn local blocking `do` plus same-body `await_all` shape by
  widening the already effect-gated multi-pending loop selector to count four
  for both `while` and `until`. Converted the focused `until` four-spawn
  coverage to a positive lowering test, added a five-spawn negative for the
  public cap, and synced the mdBook control-flow chapter, support matrix,
  backlog, live ISF spec, downstream integration spec, and Knowledge Map fact
  card to the new boundary. `perl -Iperl -c
  perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c
  t/1433-isf-until-pending-spawn-local-do-effect-widening.t`; `prove -Iperl
  t/1432-isf-loop-pending-spawn-local-do-effect-widening.t
  t/1433-isf-until-pending-spawn-local-do-effect-widening.t
  t/1434-isf-while-pending-spawn-local-do-awaitany-effect-widening.t`;
  `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t
  t/1305-isf-book-feature-matrix-audit.t
  t/1307-isf-loop-body-doc-truth-audit.t`; `prove -Iperl
  t/1376-isf-book-example-lowering-audit.t
  t/1377-book-fsm-example-generation-audit.t`; `prove -Iperl
  t/1419-isf-control-flow-effect-inventory.t
  t/1421-isf-control-flow-effect-checks.t
  t/1424-isf-control-flow-domain-binding-effects.t
  t/1425-isf-control-flow-validator-effect-migration.t
  t/1426-isf-control-flow-same-domain-validator-effect-migration.t
  t/1427-isf-control-flow-activation-domain-validator-effect-migration.t
  t/1428-isf-control-flow-binding-endpoint-validator-effect-migration.t
  t/1429-isf-control-flow-binding-expression-validator-effect-migration.t
  t/1430-isf-control-flow-rule-trigger-validator-effect-migration.t
  t/1431-isf-control-flow-rule-trigger-binding-validator-effect-migration.t
  t/1432-isf-loop-pending-spawn-local-do-effect-widening.t
  t/1433-isf-until-pending-spawn-local-do-effect-widening.t
  t/1434-isf-while-pending-spawn-local-do-awaitany-effect-widening.t`;
  `knowledge-map/scripts/check_knowledge_map.sh`;
  `scripts/check_memory_architecture.sh`; `prove -Iperl
  t/1414-docs-relative-paths-audit.t`; `mdbook build docs/book`; `git diff
  --check`; and `./bin/ci-regression isf --no-book` (Files=294, Tests=2133)
  pass.
- 2026-06-11 (`.8.21`): selected the while-contained two-spawn local blocking
  `do` plus post-`do` multi-pending `await_any` observation and later
  same-body `await_all` drain combination for the next implementation leaf:
  `(while cond (repeat n (spawn worker as w0) (spawn worker as w1) (do helper) (await_any done) (await_all done)))`.
  A read-only `perl -Iperl` probe confirms the private effect checker proves
  clean `while`/`repeat` backedges, static `w0`/`w1` identities,
  generated-top start/done handoff requirements for both instances, a local
  `helper` drain, `await_any_observes_without_full_drain` over
  `w0_done,w1_done`, `await_any_multi_pending_requires_later_drain`, and a
  later `await_all` drain for `w0_done,w1_done`; public lowering still rejects
  it at the post-`do` multi-pending `await_any` gate before the implementation
  leaf. `scripts/check_memory_architecture.sh`,
  `knowledge-map/scripts/check_knowledge_map.sh`, `prove -Iperl
  t/1414-docs-relative-paths-audit.t`, and `git diff --check` pass.
- 2026-06-11 (`.8.22`): accepted the selected while-contained two-spawn local
  blocking `do` plus post-`do` multi-pending `await_any` observation and later
  same-body `await_all` drain shape by allowing only the `while`/two-pending
  post-`do` `await_any` gate to set the existing later-drain obligation.
  Converted the focused `while` coverage to a positive lowering test, added a
  matching `until` negative, and synced the mdBook control-flow chapter,
  support matrix, backlog, live ISF spec, downstream integration spec, and
  Knowledge Map fact card to the new boundary. `perl -Iperl -c
  perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c
  t/1434-isf-while-pending-spawn-local-do-awaitany-effect-widening.t`; `prove
  -Iperl t/1432-isf-loop-pending-spawn-local-do-effect-widening.t
  t/1433-isf-until-pending-spawn-local-do-effect-widening.t
  t/1434-isf-while-pending-spawn-local-do-awaitany-effect-widening.t`;
  `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t
  t/1305-isf-book-feature-matrix-audit.t
  t/1307-isf-loop-body-doc-truth-audit.t`; `prove -Iperl
  t/1376-isf-book-example-lowering-audit.t
  t/1377-book-fsm-example-generation-audit.t`; `prove -Iperl
  t/1419-isf-control-flow-effect-inventory.t
  t/1421-isf-control-flow-effect-checks.t
  t/1424-isf-control-flow-domain-binding-effects.t
  t/1425-isf-control-flow-validator-effect-migration.t
  t/1426-isf-control-flow-same-domain-validator-effect-migration.t
  t/1427-isf-control-flow-activation-domain-validator-effect-migration.t
  t/1428-isf-control-flow-binding-endpoint-validator-effect-migration.t
  t/1429-isf-control-flow-binding-expression-validator-effect-migration.t
  t/1430-isf-control-flow-rule-trigger-validator-effect-migration.t
  t/1431-isf-control-flow-rule-trigger-binding-validator-effect-migration.t
  t/1432-isf-loop-pending-spawn-local-do-effect-widening.t
  t/1433-isf-until-pending-spawn-local-do-effect-widening.t
  t/1434-isf-while-pending-spawn-local-do-awaitany-effect-widening.t`;
  `knowledge-map/scripts/check_knowledge_map.sh`;
  `scripts/check_memory_architecture.sh`; `prove -Iperl
  t/1414-docs-relative-paths-audit.t`; `mdbook build docs/book`; `git diff
  --check`; and `./bin/ci-regression isf --no-book` (Files=294, Tests=2133)
  pass.
- 2026-06-11 (`.8.23`): selected the matching body-first `until` two-spawn
  local blocking `do` plus post-`do` multi-pending `await_any` observation and
  later same-body `await_all` drain combination for the next implementation
  leaf:
  `(until cond (repeat n (spawn worker as w0) (spawn worker as w1) (do helper) (await_any done) (await_all done)))`.
  A read-only `perl -Iperl` probe confirms the private effect checker proves
  clean `until`/`repeat` backedges, static `w0`/`w1` identities,
  generated-top start/done handoff requirements for both instances,
  same-domain activation targets, a local `helper` drain,
  `await_any_observes_without_full_drain` over `w0_done,w1_done`,
  `await_any_multi_pending_requires_later_drain`, and a later `await_all`
  drain for `w0_done,w1_done`; public lowering still rejects it at the
  post-`do` multi-pending `await_any` gate before the implementation leaf.
  `prove -Iperl
  t/1434-isf-while-pending-spawn-local-do-awaitany-effect-widening.t`,
  `scripts/check_memory_architecture.sh`,
  `knowledge-map/scripts/check_knowledge_map.sh`, `prove -Iperl
  t/1414-docs-relative-paths-audit.t`, and `git diff --check` pass.
- 2026-06-11 (`.8.24`): accepted the selected body-first `until` two-spawn
  local blocking `do` plus post-`do` multi-pending `await_any` observation and
  later same-body `await_all` drain shape by widening the exact post-`do`
  `await_any` selector from the shipped `while` one-loop context to the
  matching `until` one-loop context. Converted stale `until` negatives to
  positive lowering coverage, added a wider three-spawn post-`do` `await_any`
  negative, and synced the mdBook control-flow chapter, support matrix,
  backlog, live ISF spec, downstream integration spec, and Knowledge Map fact
  card to the new boundary. `perl -Iperl -c
  perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c
  t/1433-isf-until-pending-spawn-local-do-effect-widening.t`; `perl -Iperl
  -c t/1434-isf-while-pending-spawn-local-do-awaitany-effect-widening.t`;
  `prove -Iperl t/1432-isf-loop-pending-spawn-local-do-effect-widening.t
  t/1433-isf-until-pending-spawn-local-do-effect-widening.t
  t/1434-isf-while-pending-spawn-local-do-awaitany-effect-widening.t`;
  `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t
  t/1305-isf-book-feature-matrix-audit.t
  t/1307-isf-loop-body-doc-truth-audit.t`; `prove -Iperl
  t/1376-isf-book-example-lowering-audit.t
  t/1377-book-fsm-example-generation-audit.t`; `prove -Iperl
  t/1419-isf-control-flow-effect-inventory.t
  t/1421-isf-control-flow-effect-checks.t
  t/1424-isf-control-flow-domain-binding-effects.t
  t/1425-isf-control-flow-validator-effect-migration.t
  t/1426-isf-control-flow-same-domain-validator-effect-migration.t
  t/1427-isf-control-flow-activation-domain-validator-effect-migration.t
  t/1428-isf-control-flow-binding-endpoint-validator-effect-migration.t
  t/1429-isf-control-flow-binding-expression-validator-effect-migration.t
  t/1430-isf-control-flow-rule-trigger-validator-effect-migration.t
  t/1431-isf-control-flow-rule-trigger-binding-validator-effect-migration.t
  t/1432-isf-loop-pending-spawn-local-do-effect-widening.t
  t/1433-isf-until-pending-spawn-local-do-effect-widening.t
  t/1434-isf-while-pending-spawn-local-do-awaitany-effect-widening.t`;
  `mdbook build docs/book`; `knowledge-map/scripts/check_knowledge_map.sh`;
  `scripts/check_memory_architecture.sh`; `git diff --check`; and
  `./bin/ci-regression isf --no-book` (Files=294, Tests=2133) pass.
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
- `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.7.4`: `211bffda`,
  `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.7.4: route binding endpoints through effects`.
- `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.7.5`: `5386e913`,
  `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.7.5: route binding expressions through effects`.
- `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.7.6`: `44459c7d`,
  `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.7.6: route rule trigger targets through effects`.
- `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.7.7`: `428ed31f`,
  `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.7.7: route rule trigger bindings through effects`.
- `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.1`: `37099c8f`,
  `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.1: select pending-spawn local-do widening`.
- `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.2`: `6f5e2e82`,
  `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.2: accept while pending-spawn local-do`.
- `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.3`: `f56a41db`,
  `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.3: select until pending-spawn local-do`.
- `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.4`: `76125081`,
  `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.4: accept until pending-spawn local-do`.
- `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.5`: `0822d796`,
  `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.5: select pending-spawn awaitany local-do`.
- `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.6`: `7b0db6f1`,
  `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.6: accept pending-spawn awaitany local-do`.
- `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.7`: `62f5d87f`,
  `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.7: select multi-pending local-do awaitall`.
- `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.8`: `a11f3680`,
  `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.8: accept multi-pending local-do awaitall`.
- `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.9`: `f28d069a`,
  `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.9: select until multi-pending local-do`.
- `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.10`: `ae511ab1`,
  `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.10: accept until multi-pending local-do`.
- `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.11`: `36713bcf`,
  `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.11: select until pending-spawn awaitany local-do`.
- `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.12`: `0a753ca1`,
  `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.12: accept until pending-spawn awaitany local-do`.
- `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.13`: `3905be72`,
  `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.13: select wider pending-spawn local-do fanout`.
- `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.14`: `672015ec`,
  `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.14: accept wider pending-spawn local-do fanout`.
- `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.15`: `eb81601f`,
  `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.15: select until wider pending-spawn local-do fanout`.
- `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.16`: this commit,
  `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.16: accept until wider pending-spawn local-do fanout`.
- `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.17`: this commit,
  `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.17: select wider pending-spawn local-do fanout`.
- `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.18`: this commit,
  `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.18: accept while four-spawn local-do fanout`.
- `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.19`: this commit,
  `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.19: select until four-spawn local-do fanout`.
- `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.20`: this commit,
  `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.20: accept until four-spawn local-do fanout`.
- `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.21`: this commit,
  `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.21: select post-do awaitany local-do fanout`.
- `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.22`: this commit,
  `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.22: accept post-do awaitany local-do fanout`.
- `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.23`: this commit,
  `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.23: select until post-do awaitany local-do fanout`.
- `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.24`: this commit,
  `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.8.24: accept until post-do awaitany local-do fanout`.
