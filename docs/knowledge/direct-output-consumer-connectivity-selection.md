---
id: direct-output-consumer-connectivity-selection
title: Direct output consumer connectivity starts with output-port sources
answers:
  - "what is the selected direct output consumer connectivity slice?"
  - "where should direct output-port source connectivity come from?"
  - "are direct output-drive consumers ready for StructuralRTLIR?"
date: 2026-06-12
status: current
tags: [direct-hdl, structural-rtl-ir, lowered-rtl-ir, output-drive, task-tree]
evidence: docs/tasks/R11-DIRECT-STRUCTURAL-OUTPUT-CONSUMERS.md; perl/FSM/IR/LoweredRTLIR.pm; perl/FSM/IR/LoweredRTLIRBuilder.pm; perl/FSM/Pipeline/GeneratedModuleInfoBuilder.pm; perl/FSM/IR/StructuralRTLIR.pm; perl/FSM/IR/StructuralRTLIRBuilder.pm; perl/FSM/Support/NormalizedSemanticLoweredRTLIRContract.pm; t/311-normalized-semantic-report-contract.t; fsm/apb_requester.fsm
reverify: rg -n 'R11-DIRECT-STRUCTURAL-OUTPUT-CONSUMERS.2|output-port source summaries|output_drive_families' docs/tasks/R11-DIRECT-STRUCTURAL-OUTPUT-CONSUMERS.md perl/FSM/IR/LoweredRTLIRBuilder.pm perl/FSM/Pipeline/GeneratedModuleInfoBuilder.pm t/311-normalized-semantic-report-contract.t
---

`R11-DIRECT-STRUCTURAL-OUTPUT-CONSUMERS.2` is the selected first direct output
consumer connectivity implementation slice.

The existing lowered layer already exposes direct output-drive families in
`LoweredRTLIR.output_drive_families[]`, and `GeneratedModuleInfoBuilder`
mirrors those families into `module_info` and normalized semantic JSON.
The bounded lowered contract defines the output-drive family keys as
`default_value`, `driver_blocks`, `driver_count`, `driver_enable_signals`,
`family_enable_signals`, `multiplexer_type`, `reset_value`,
`rhs_enable_families`, `rhs_values`, `signal_name`, and `width`.

The selected structural bridge is deliberately narrower than the full lowered
family: direct `StructuralRTLIR.ports[]` output entries should get a compact
`source` summary derived from the matching lowered output-drive family. The
first source summary should include `kind`, `signal_name`, `multiplexer_type`,
`driver_count`, `driver_blocks`, `rhs_values`, `driver_enable_signals`, and
`family_enable_signals`.

Nested `rhs_enable_families[]`, default/reset values, always-block body
consumer modeling, direct instances/links, and HDL emission remain outside
the selected first slice.
