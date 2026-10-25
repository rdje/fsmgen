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
reverify: python3 -B docs/audits/lispish-provider-contract-20261025/observe.py && scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib t/2106-lispish-parser-provider.t && grep -rln "package FSM::Scheduler::ISF" perl/FSM/Scheduler/ISF*
---

ISF is IAL-1 (`R14`); HLL sugar desugars into it (see `isf-abstraction-layering`).

1. `FSM::Adapter::ISF->parse_source` produces an actor AST.
2. `FSM::Scheduler::ISF->lower` drives `LoweringIR`: transactions/loops/whens
   become explicit states and **`.fsm` TEXT**.
3. `FSM::Adapter::FSMGenFull` parses it into `module_info`.
4. `FSM::Backend::GeneratedModuleEmitter` emits SystemVerilog/Verilog.

`FSM::Scheduler::ISF->report` produces JSON via `FSM::Scheduler::ISF::Emitter::JSON` (see [[isf-schedule-report-additive-keys]]).

2026-10-25: FSM/ISF/PPIF use `Lispish::multi`; cached `single` compiles
module-origin `specs/Lispish.spec` via `LinkedSpec::Get`, without PPlugin/discovery.
Relative loads survive chdir; missing/escaped resources refuse. Parsers retain
roots across compilations. .12.1 preserves old RED; PUBLICATION .12.2 tests
current AST/API/CWD/error/stability. Legacy retirement is separate; full3
allocation unknown.
