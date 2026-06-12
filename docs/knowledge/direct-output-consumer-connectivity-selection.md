---
id: direct-output-consumer-connectivity-selection
title: Direct output consumer connectivity ships output-port sources
answers:
  - "what is the selected direct output consumer connectivity slice?"
  - "where should direct output-port source connectivity come from?"
  - "are direct output-drive consumers ready for StructuralRTLIR?"
date: 2026-06-12
status: current
tags: [direct-hdl, structural-rtl-ir, lowered-rtl-ir, output-drive, task-tree]
evidence: docs/tasks/R11-DIRECT-STRUCTURAL-OUTPUT-CONSUMERS.md; perl/FSM/IR/LoweredRTLIR.pm; perl/FSM/IR/LoweredRTLIRBuilder.pm; perl/FSM/Pipeline/GeneratedModuleInfoBuilder.pm; perl/FSM/IR/StructuralRTLIR.pm; perl/FSM/IR/StructuralRTLIRBuilder.pm; perl/FSM/Support/NormalizedSemanticLoweredRTLIRContract.pm; perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm; t/1333-direct-structural-rtl-ir-projection.t; t/163-forward-structural-rtl-ir-surface.t; t/311-normalized-semantic-report-contract.t
reverify: prove -Iperl t/1333-direct-structural-rtl-ir-projection.t t/163-forward-structural-rtl-ir-surface.t t/341-normalized-semantic-structural-rtl-ir-contract.t t/334-normalized-semantic-forward-ir-contract.t t/330-normalized-semantic-payload-contract.t t/311-normalized-semantic-report-contract.t
---

`R11-DIRECT-STRUCTURAL-OUTPUT-CONSUMERS.2` shipped the first direct output
consumer connectivity implementation slice.

The existing lowered layer already exposes direct output-drive families in
`LoweredRTLIR.output_drive_families[]`, and `GeneratedModuleInfoBuilder`
mirrors those families into `module_info` and normalized semantic JSON.
The bounded lowered contract defines the output-drive family keys as
`default_value`, `driver_blocks`, `driver_count`, `driver_enable_signals`,
`family_enable_signals`, `multiplexer_type`, `reset_value`,
`rhs_enable_families`, `rhs_values`, `signal_name`, and `width`.

The structural bridge is deliberately narrower than the full lowered family:
direct `StructuralRTLIR.ports[]` output entries now get a compact `source`
summary derived from the matching lowered output-drive family. The source
summary includes `kind`, `signal_name`, `multiplexer_type`, `driver_count`,
`driver_blocks`, `rhs_values`, `driver_enable_signals`, and
`family_enable_signals`.

Nested `rhs_enable_families[]`, default/reset values, always-block body
consumer modeling, direct instances/links, and HDL emission remain outside
the selected first slice.
