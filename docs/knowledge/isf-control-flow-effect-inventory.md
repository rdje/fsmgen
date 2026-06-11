---
id: isf-control-flow-effect-inventory
title: ISF shadow control-flow/effect inventory module
answers:
  - "where is the ISF control-flow effect inventory implemented?"
  - "where are ISF control-flow effect invariant checks implemented?"
  - "where is ISF child activation planning derived from effect inventory?"
  - "where are ISF outstanding child lifetime checks implemented?"
  - "where are ISF activation domain, binding, and CDC effects modeled?"
  - "which validator path first consumes the ISF control-flow effect checker?"
  - "how does FSMGen model ISF regions and activation effects in shadow mode?"
  - "where are await_any observe versus await_all drain effects recorded?"
  - "what module owns the initial compositional control-flow activation model?"
date: 2026-06-10
status: current
tags: [isf, control-flow, architecture, activation, scheduling, cdc]
evidence: perl/FSM/Scheduler/ISF/ControlFlowEffects.pm; perl/FSM/Scheduler/ISF/LoweringIR.pm; t/1419-isf-control-flow-effect-inventory.t; t/1421-isf-control-flow-effect-checks.t; t/1422-isf-control-flow-child-plan.t; t/1423-isf-control-flow-lifetime-checks.t; t/1424-isf-control-flow-domain-binding-effects.t; t/1425-isf-control-flow-validator-effect-migration.t; t/1426-isf-control-flow-same-domain-validator-effect-migration.t; t/1427-isf-control-flow-activation-domain-validator-effect-migration.t; t/1428-isf-control-flow-binding-endpoint-validator-effect-migration.t; t/1429-isf-control-flow-binding-expression-validator-effect-migration.t; docs/tasks/ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.md; docs/decisions/0013-compositional-control-flow-activation-model.md
reverify: prove -Iperl t/1419-isf-control-flow-effect-inventory.t t/1421-isf-control-flow-effect-checks.t t/1422-isf-control-flow-child-plan.t t/1423-isf-control-flow-lifetime-checks.t t/1424-isf-control-flow-domain-binding-effects.t t/1425-isf-control-flow-validator-effect-migration.t t/1426-isf-control-flow-same-domain-validator-effect-migration.t t/1427-isf-control-flow-activation-domain-validator-effect-migration.t t/1428-isf-control-flow-binding-endpoint-validator-effect-migration.t t/1429-isf-control-flow-binding-expression-validator-effect-migration.t
---

The initial compositional ISF control-flow model lives in
`FSM::Scheduler::ISF::ControlFlowEffects`. It is a private, read-only shadow
inventory over parsed actor clauses and is not wired into lowering, generated
HDL, or public schedule reports yet.

The inventory records typed transaction/`when`/`switch`/`while`/`until`/`repeat`
regions, loop/repeat backedges, local and generated child starts, spawned child
starts, `await_any` observation effects, `await_all` drain effects, outstanding
children at region exits, binding/domain metadata, and deterministic generated
child instance names.

The same module exposes `check_actor` / `check_inventory` shadow checks. These
return structured proofs and violations for outstanding-child lifetime,
loop/repeat backedge dominance, `await_any` observe-not-drain semantics, and
deterministic generated-child instance identity without changing public
lowering behavior.
Its outstanding-child lifetime diagnostics distinguish loop/repeat backedges
that can re-enter with live children from non-loop region exits that leave
children live, while single-pending `await_any` proves that no child remains
outstanding and multi-pending `await_any` records a later-drain obligation.

It also exposes `plan_actor` / `plan_inventory`, a private child-plan projection
that derives local child start/done wire requirements, generated child instance
plans, and sync points from the same effect list. The projection is tested
against current emitted `.fsm` / `_top` artifacts but is not yet used to drive
lowering.

The private child-start effects now also carry explicit activation domain
contracts, binding handoff records, and generated-top/CDC requirements. The
checker proves same-domain activations, covered cross-domain blocking `do`
through declared activation crossings, generated-top binding handoffs, and CDC
start/done handoffs; uncovered cross-domain `do` and cross-domain `spawn`
remain private violations that mirror the existing fail-closed public
validators.

`LoweringIR` now consumes the first effect-checker proof in a production
validator path: covered cross-domain blocking `do` skips the same-domain target
failure only when `ControlFlowEffects` proves
`activation_crossing_covers_child_start`. The existing activation-crossing
placement gate remains in force, so deeper unsupported placements and
cross-domain `spawn` still fail closed with their prior diagnostics.
The same validator now also skips the direct child-target same-domain check only
when the effect checker proves `activation_target_is_same_domain`; activation
domain metadata is still checked separately, so mismatched `(domain ...)`
metadata keeps the prior public diagnostic.
The activation-domain metadata check is now migrated too: the validator skips
the direct metadata-domain comparison only when `ControlFlowEffects` proves
`activation_domain_is_explicit` for the same transaction, child, and authored
domain. A proof for one domain does not hide a mismatched metadata site for the
same child.
Activation binding endpoint domains are also represented in the effect checker:
simple input/output actor endpoints get `binding_endpoint_is_same_domain`
proofs or `binding_endpoint_domain_mismatch` violations. The public validator
skips the direct binding endpoint domain walk only for those same-domain
endpoint proofs; expression bindings and cross-domain endpoints keep the prior
validator behavior.
Input binding list expressions are represented as recursive endpoint facts too:
`binding_expression_endpoints_are_same_domain` proves every known actor-signal
endpoint in the expression is in the caller domain, while
`binding_expression_endpoint_domain_mismatch` records cross-domain expression
endpoints. The validator skips the recursive input-binding expression read walk
only for the all-same-domain proof.
