---
id: direct-structural-full-hdl-rerouting-selection
title: Full direct SystemVerilog rerouting is deferred behind behavior-body StructuralRTLIR prerequisites
answers:
  - "is full direct SystemVerilog rerouting through StructuralRTLIR ready?"
  - "why is full direct HDL rerouting deferred?"
  - "what StructuralRTLIR prerequisites block full direct rerouting?"
  - "what did R11-DIRECT-STRUCTURAL-FULL-HDL-REROUTING select?"
date: 2026-06-12
status: current
tags: [direct-hdl, structural-rtl-ir, systemverilog, task-tree]
evidence: docs/tasks/R11-DIRECT-STRUCTURAL-FULL-HDL-REROUTING.md; docs/tasks/R11-DIRECT-STRUCTURAL-HDL-REROUTING.md; docs/tasks/IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.md; perl/FSM/Pipeline/DirectGenerationOrchestrator.pm; perl/FSM/Backend/GeneratedModuleEmitter.pm; perl/FSM/Backend/VerilogFamily/StructuralRTLIREmitter.pm; perl/FSM/IR/StructuralRTLIRBuilder.pm; perl/FSM/IR/StructuralRTLIR.pm; docs/book/src/14-feature-backlog.md
reverify: prove -Iperl t/194-generated-module-emitter.t t/293-systemverilog-post-flattening-assembly-support.t t/1333-direct-structural-rtl-ir-projection.t
---

Selector `R11-DIRECT-STRUCTURAL-FULL-HDL-REROUTING.1` did not select a broader
direct SystemVerilog reroute implementation target.

The current direct `StructuralRTLIR` surface owns ports, declaration nets,
generated-enable assignment records, scalar auxiliary-assignment mirrors,
generated-enable net source/target connectivity, direct input-port target
connectivity, compact output-port source summaries, and the already shipped
top state/standalone-DT generated-enable marker handoff. It does not yet own
the ordered direct behavior body needed for full HDL reproduction: state
register update regions, next-state/output always blocks, selector/conflict
assertion regions, temporal/immediate assertion augmentation, and final backend
tail assembly remain outside the structural contract.

Full direct SystemVerilog rerouting stays deferred until those behavior-body
regions have exact task-tree ownership and can reproduce focused direct HDL
without parsing unmarked generated text.
