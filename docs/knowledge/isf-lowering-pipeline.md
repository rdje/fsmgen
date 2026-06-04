---
id: isf-lowering-pipeline
title: How an ISF actor becomes SystemVerilog — the lowering pipeline stages and where each lives
answers:
  - "how does ISF get compiled to SystemVerilog?"
  - "where does ISF lowering happen?"
  - "what is the ISF to FSM to HDL pipeline?"
  - "which module parses ISF / lowers ISF / emits the schedule report?"
  - "where is the .fsm text produced from an ISF actor?"
  - "how does report() / the JSON schedule report get built?"
date: 2026-06-03
status: current
tags: [isf, architecture, pipeline, lowering]
evidence: perl/FSM/Adapter/ISF.pm; perl/FSM/Scheduler/ISF.pm; perl/FSM/Scheduler/ISF/LoweringIR.pm; perl/FSM/Scheduler/ISF/Emitter/JSON.pm; perl/FSM/Backend/GeneratedModuleEmitter.pm; docs/book/src/13-intent-scheduling.md
reverify: grep -rln "package FSM::Scheduler::ISF" perl/FSM/Scheduler/ISF*
---

The ISF lane (`R14`) lowers in stages, each in its own module:

1. **Parse** — `FSM::Adapter::ISF->parse_source` → an actor AST.
2. **Lower** — `FSM::Scheduler::ISF->lower` drives `LoweringIR` to expand
   transactions/loops/whens into explicit states and emit **`.fsm` TEXT**.
3. **Re-parse** — that `.fsm` text is parsed by `FSM::Adapter::FSMGenFull` into a
   `module_info`.
4. **Emit HDL** — `FSM::Backend::GeneratedModuleEmitter` turns `module_info`
   into SystemVerilog/Verilog.

Separately, **`FSM::Scheduler::ISF->report`** produces the JSON **schedule
report** via `FSM::Scheduler::ISF::Emitter::JSON` (see
[[isf-schedule-report-additive-keys]]). The narrative home is the book chapter
`docs/book/src/13-intent-scheduling.md`. ISF is the IAL-1 layer; HLL sugar
desugars *into* ISF (see the `isf-abstraction-layering` memory).
