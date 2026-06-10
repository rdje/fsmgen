---
id: isf-control-flow-effect-inventory
title: ISF shadow control-flow/effect inventory module
answers:
  - "where is the ISF control-flow effect inventory implemented?"
  - "how does FSMGen model ISF regions and activation effects in shadow mode?"
  - "where are await_any observe versus await_all drain effects recorded?"
  - "what module owns the initial compositional control-flow activation model?"
date: 2026-06-10
status: current
tags: [isf, control-flow, architecture, activation, scheduling]
evidence: perl/FSM/Scheduler/ISF/ControlFlowEffects.pm; t/1419-isf-control-flow-effect-inventory.t; docs/tasks/ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.md; docs/decisions/0013-compositional-control-flow-activation-model.md
reverify: prove -Iperl t/1419-isf-control-flow-effect-inventory.t
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
