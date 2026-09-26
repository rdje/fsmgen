---
id: isf-declared-output-preservation
title: Declared actor outputs survive undriven-port inference without invented values
answers:
  - "why did an undriven actor output disappear from generated HDL?"
  - "do declared output roles survive domain lowering and MCP queries?"
  - "does retaining an undriven output imply a defined or reset value?"
date: 2026-09-26
status: current
tags: [isf, interface, output, lowering, domains, semantics, mcp]
evidence: perl/FSM/Synthesis/EnableGraph/AssignmentSupport.pm; perl/FSM/IR/LoweredRTLIRBuilder.pm; t/1901-reset-only-output-behavior.t; perl/FSM/Scheduler/ISF/LoweringIR.pm; t/1900-isf-declared-output-preservation.t; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md; docs/book/src/13a-actor-interface.md
reverify: FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME=1 FSMGEN_RESET_GHDL=.artifacts/cache/providers/ghdl/6.0.0/llvm-jit-tool/ghdl-llvm-jit-6.0.0-macos15-aarch64/bin/ghdl scripts/run_with_ram_guard.sh -- prove -Iperl t/1900-isf-declared-output-preservation.t t/1901-reset-only-output-behavior.t
---

Parent lowering now places both declared input and output roles in
`explicit_interface_ports`. The existing emitter carries them in `+interface`
while widths/types remain in `+size`. An output no longer depends on an
ordinary assignment for its public identity. Domain modules take the same
path, so their generated top retains output routes. Unrelated parent outputs
do not become generated transaction-child ports.

T1900 retains the original positive-width SPECFORGE source from the tracked
intake audit, literal/driven controls, a scalar spare and named/multiple
domains. Actual materialized FSMs, realized semantic outputs, schedule counts
and complete native/API/newline MCP reports agree. Verilog-family named-port
admission and wrong-width lint controls provide independent interface
evidence. Direct VHDL emission retains the declaration and passes analysis
with the existing repository-local GHDL provider selected explicitly through
`FSMGEN_RESET_GHDL`. The initial PATH-only run skipped that analysis; the
provider-backed rerun closes this declaration-analysis gap.
The reset-only output gap discovered during interface repair is superseded by
`.35`. `AssignmentSupport` now adds reset-and-hold plans for output signals
with explicit reset metadata, no data writer and an effective hardware reset.
The existing register emitter owns timing and polarity. LoweredRTLIR keeps
these drive families with zero data-driver blocks and no RHS/enable families.
T1901 qualifies native/API/newline parity and actual reset/hold behavior in both
Verilog targets and supported direct VHDL. T1900 qualifies interface identity;
plain undriven ports imply no value or assignment. Generic widths and optional
presence remain separately owned extensions.

T1901's explicit clock-only control confirms no register initialization is
invented. Direct VHDL rejects the state process without a reset branch in
`VHDL::_split_if_else_assignments`; `.36` owns that extension after the
existing SV-backed IAL completeness prerequisite. This is separate from the
qualified reset-bearing VHDL output behavior.
