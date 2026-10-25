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
  - "why is PPlugin still needed?"
date: 2026-06-03
status: current
tags: [isf, architecture, pipeline, lowering]
evidence: docs/audits/lispish-provider-contract-20261025/contract.json; perl/Lispish.pm; perl/PPlugin.pm; perl/FSM/Adapter/ISF.pm; perl/FSM/Scheduler/ISF.pm; perl/FSM/Scheduler/ISF/LoweringIR.pm; perl/FSM/Scheduler/ISF/Emitter/JSON.pm; perl/FSM/Backend/GeneratedModuleEmitter.pm; docs/book/src/13-intent-scheduling.md
reverify: python3 -B docs/audits/lispish-provider-contract-20261025/observe.py && grep -rln "package FSM::Scheduler::ISF" perl/FSM/Scheduler/ISF*
---

ISF is IAL-1 (`R14`); HLL sugar desugars into it (see `isf-abstraction-layering`).

1. `FSM::Adapter::ISF->parse_source` produces an actor AST.
2. `FSM::Scheduler::ISF->lower` drives `LoweringIR`: transactions/loops/whens
   become explicit states and **`.fsm` TEXT**.
3. `FSM::Adapter::FSMGenFull` re-parses that text into `module_info`.
4. `FSM::Backend::GeneratedModuleEmitter` emits SystemVerilog/Verilog.

`FSM::Scheduler::ISF->report` separately produces JSON schedule reports via
`FSM::Scheduler::ISF::Emitter::JSON` (see [[isf-schedule-report-additive-keys]]).
Book: `docs/book/src/13-intent-scheduling.md`.

Provider intake, 2026-10-25: FSM/ISF/PPIF use `Lispish::multi`; `single` caches
`PPlugin->_get_parser('Lispish')` via AUTOLOAD/exec and `LinkedSpec::get_parser`.
Lookup reaches root-wide `PathSearch`; direct `LinkedSpec::Get` of
`specs/Lispish.spec` passes literal ASTs without discovery. Shared `top_rule`
breaks a first parser after another grammar compiles. PUBLICATION .12.2 owns
both repairs; full3 allocation remains unknown.
