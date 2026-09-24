---
id: direct-hdl-generated-enable-reroute
title: Direct SystemVerilog top generated-enable emission is rerouted through StructuralRTLIR
answers:
  - "does direct HDL emission use StructuralRTLIR?"
  - "which direct HDL block is rerouted through StructuralRTLIR?"
  - "are generated enable assignments emitted from StructuralRTLIR?"
  - "does direct HDL rerouting parse emitted HDL text?"
  - "how are case-distinct generated enable name collisions prevented?"
  - "why did PENABLE semantic drivers change across hash seeds?"
  - "why does Icarus reject onehot selector assertions while Verilator passes?"
  - "where is the standalone onehot simulator qualification probe?"
date: 2026-09-24
status: current
tags: [direct-hdl, structural-rtl-ir, generated-enable, systemverilog]
evidence: perl/FSM/Pipeline/DirectGenerationOrchestrator.pm; perl/FSM/Backend/GeneratedModuleEmitter.pm; perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/PostFlatteningAssemblySupport.pm; perl/FSM/IR/StructuralRTLIRBuilder.pm; t/194-generated-module-emitter.t; t/293-systemverilog-post-flattening-assembly-support.t; t/163-forward-structural-rtl-ir-surface.t; t/1333-direct-structural-rtl-ir-projection.t; docs/tasks/R11-DIRECT-STRUCTURAL-HDL-REROUTING.md
reverify: prove -Iperl t/1866-generated-enable-name-identity.t t/1405-codegen-multi-expression-set.t t/194-generated-module-emitter.t t/293-systemverilog-post-flattening-assembly-support.t t/163-forward-structural-rtl-ir-surface.t t/1333-direct-structural-rtl-ir-projection.t
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

Assignment enable identity is allocated before factorization by
`FSM::Synthesis::EnableGraph::AssignmentSupport`. One fresh registry per
complete analysis build covers DT-local and LHS-level families, reserving
module signals, effective system ports, parameters and top-level state/DT
enable names. Sorted original LHS/DT/RHS
traversal and suffix probing separate case/punctuation and cross-family
collisions while preserving available readable candidates. Muxes, structural
records and emitted HDL consume the allocated identity.

The prior per-LHS registry allowed `PENABLE` and `penable` to share
`penable_0_en`; duplicate factorization context keys then replaced one original
condition with the other in hash-dependent order. T1866 guards this and related
collisions; the prior expression-alias guard remains T1405. Exact baseline,
isolated controls, actual CLI/MCP comparisons and HDL behavior evidence are in
`docs/audits/mcp-feature-coverage-20260924/enable-identity-repair.json` under
`SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.2.1`. This is an assignment-enable
namespace contract, not a universal generated-identifier collision claim.

Simulator qualification is distinct from enable identity. The installed Icarus
13.0 output-context probe returns a false `$onehot0` result for one-hot
concatenations while packed/literal checks and the basic truth-table control
pass. APB assertion diagnostics also depend on expression context. Do not
accept a final testbench PASS after simulator ERRORs. Assertion-enabled
Verilator 5.050 passes the bounded probe and APB transfer oracle; this is not
universal four-state or scheduling equivalence. Compiler conflict checks stay
unchanged; T1542's native Verilog Icarus lane has no SystemVerilog assertions.
Reproduction, explicit expected-value checker, negative controls and versions:
`docs/audits/mcp-feature-coverage-20260924/onehot-qualification.json` and
`docs/book/src/09-generated-hdl-debugging-and-inspection.md` (runtime simulator
qualification), owned by `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.2.6`.
