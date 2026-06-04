---
id: loop-early-exit-target-hook
title: Mid-loop exit/continue targets come from loop_exit_target computed in _link_states
answers:
  - "where does (exit-when) / (continue-when) jump to?"
  - "how is the loop exit target for a mid-loop early exit computed?"
  - "what is loop_exit_target in the ISF lowering?"
  - "how do exit-when and continue-when differ in their target?"
  - "where is the clean hook for ISF loop early-exit?"
date: 2026-06-03
status: current
tags: [isf, control-flow, loops, lowering]
evidence: perl/FSM/Scheduler/ISF/LoweringIR.pm (_link_states per-loop pass stamps loop_exit_target; _link_loop_state wires the edges); docs/tasks/ISF-LOOP-EARLY-EXIT.md
reverify: grep -n "loop_exit_target" perl/FSM/Scheduler/ISF/LoweringIR.pm
---

`_link_states` already computes, per loop, **`loop_exit_target`** = the state
immediately after the loop's last state. That single pre-computed target is the
hook the whole early-exit family reuses:

- **`(exit-when cond)`** lowers to a `loop_exit_when` decision whose TRUE edge
  takes `loop_exit_target` (leave the loop) and FALSE edge falls through to the
  next body clause.
- **`(continue-when cond)`** is the same shape but its TRUE edge takes the loop's
  **tail check** (re-evaluate the condition), not the exit.

A `when` body nested in the loop reuses this automatically because its body
states are part of the loop's `loop_body_state_names`. A `loop_exit_when` left
with no stamped `loop_exit_target` (i.e. not inside a loop) fails closed. Each
site is advertised in the report's `loop_early_exits[]`
(see [[isf-schedule-report-additive-keys]]).
