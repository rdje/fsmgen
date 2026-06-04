---
id: isf-fsm-verification-boundary
title: ISF-originated verification references signals, never the FSM state variable
answers:
  - "can ISF assertions reference current_state or state_active?"
  - "why doesn't (at NAME) lower to current_state == STATE?"
  - "how do I anchor a position in ISF verification without touching the state variable?"
  - "what is the ISF/FSM separation rule for verification?"
  - "Unsupported expression operator <point>_active"
date: 2026-06-03
status: current
tags: [isf, verification, boundary, anchors]
evidence: docs/decisions/0009; docs/decisions/0010; perl/FSM/Scheduler/ISF/LoweringIR.pm (_resolve_at_references generates a driven *_active signal)
reverify: grep -n "_active" perl/FSM/Scheduler/ISF/LoweringIR.pm | head
---

ISF-originated verification (asserts/monitors/anchors) must reference **signals**,
never the FSM state variable (`current_state` / `state_active`). Accessing the
state variable from the ISF layer breaks the ISF↔FSM separation.

To anchor a position, ISF generates a driven **`*_active` signal** (lazily, only
for referenced points) and resolves `(at NAME)` to that **bare scalar leaf** —
not `($signal)` (which parses as a 1-arg operator call and fails with
`Unsupported expression operator '<point>_active'`). This mirrors how a monitor's
`arm` signal works. Canonical home: decision records `0009`/`0010` and the
`isf-fsm-boundary-no-state-in-verification` memory.
