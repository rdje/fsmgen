---
id: direct-hdl-generated-enable-reroute
title: Direct SystemVerilog top generated-enable emission is rerouted through StructuralRTLIR
answers:
  - "does direct HDL emission use StructuralRTLIR?"
  - "which direct HDL block is rerouted through StructuralRTLIR?"
  - "are generated enable assignments emitted from StructuralRTLIR?"
  - "does direct HDL rerouting parse emitted HDL text?"
date: 2026-06-12
status: current
tags: [direct-hdl, structural-rtl-ir, generated-enable, systemverilog]
evidence: perl/FSM/Pipeline/DirectGenerationOrchestrator.pm; perl/FSM/Backend/GeneratedModuleEmitter.pm; perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/PostFlatteningAssemblySupport.pm; perl/FSM/IR/StructuralRTLIRBuilder.pm; t/194-generated-module-emitter.t; t/293-systemverilog-post-flattening-assembly-support.t; t/163-forward-structural-rtl-ir-surface.t; t/1333-direct-structural-rtl-ir-projection.t; docs/tasks/R11-DIRECT-STRUCTURAL-HDL-REROUTING.md
reverify: prove -Iperl t/194-generated-module-emitter.t t/293-systemverilog-post-flattening-assembly-support.t t/163-forward-structural-rtl-ir-surface.t t/1333-direct-structural-rtl-ir-projection.t
---

Direct SystemVerilog generation now reroutes only the top state and
standalone-DT generated-enable condition block through `StructuralRTLIR`
assignment records.

The legacy direct backend emits explicit temporary markers around that block
only when the direct pipeline asks for the reroute handoff. After
`StructuralRTLIR` is built, `FSM::Backend::GeneratedModuleEmitter` replaces the
marked block with the matching top generated-enable assignment records and
removes the markers before final HDL is returned. Unmarked HDL text is not
parsed.

DT-specific WEN/EN assignments, LHS-level enables, output-drive and
always-block bodies, direct instances/links, VHDL emission, and full direct
module emission remain outside this reroute slice.
