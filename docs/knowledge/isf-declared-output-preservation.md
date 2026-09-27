---
id: isf-declared-output-preservation
title: Explicit output and internal roles survive usage inference without invented values
answers:
  - "why did an undriven actor output disappear from generated HDL?"
  - "do declared output roles survive domain lowering and MCP queries?"
  - "does retaining an undriven output imply a defined or reset value?"
  - "how do explicit internal signal roles preserve declaration and reset behavior?"
date: 2026-09-26
status: current
tags: [isf, interface, internal, output, lowering, domains, semantics, mcp]
evidence: t/1904-isf-generated-child-storage-reads.t; t/1903-isf-internal-storage-ownership.t; t/1902-explicit-internal-signal-roles.t; perl/FSM/IR/IntentHIRBuilder.pm; perl/FSM/Synthesis/EnableGraph/AssignmentSupport.pm; perl/FSM/IR/LoweredRTLIRBuilder.pm; t/1901-reset-only-output-behavior.t; perl/FSM/Scheduler/ISF/LoweringIR.pm; t/1900-isf-declared-output-preservation.t; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md; docs/book/src/13a-actor-interface.md
reverify: FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME=1 FSMGEN_RESET_GHDL=.artifacts/cache/providers/ghdl/6.0.0/llvm-jit-tool/ghdl-llvm-jit-6.0.0-macos15-aarch64/bin/ghdl scripts/run_with_ram_guard.sh -- prove -Iperl t/1900-isf-declared-output-preservation.t t/1901-reset-only-output-behavior.t t/1902-explicit-internal-signal-roles.t t/1903-isf-internal-storage-ownership.t
---

ISF parent/domain lowering carries declared input/output roles in
`explicit_interface_ports` and then `+interface`; widths/types remain in
`+size`. Unused inputs and unwritten outputs retain identity. Unrelated parent
outputs do not become child ports. T1900 retains the original SPECFORGE case,
literal/driven controls and domain cases, checking materialized FSM, semantic
and schedule inventories, complete native/API/newline MCP parity, independent
Verilog port/width admission and qualified local GHDL declaration analysis.

The reset-only output gap is superseded by `.35`: AssignmentSupport creates
reset/hold plans with no fabricated data/RHS/enable records when an explicit
reset value and effective hardware reset exist. The shared emitter owns reset
timing/polarity; LoweredRTLIR retains these output families. T1901 independently
simulates both Verilog targets and supported direct VHDL, including zero and
nonzero values, reset edges and hold. Plain undriven ports imply no value.

Direct IAL0 `.39.1` adds `(internal NAME)` to the same carrier. The parser
rejects conflicting roles; SignalAnalyzer rejects internal output markers and
system-port collisions, then retains explicit internals in FSMModule. Module
planning declares them without exporting ports, and IntentHIR port analysis
excludes them. Reset-only planning also covers explicit internals. T1902
qualifies unused/typed/read-only/written declarations, exact external ports,
complete native/API/newline parity and independent reset/write/hold behavior.
Ordinary/domain ISF storage is qualified by T1903; T1904 adds explicit child
scalar/bank/record live reads and exact child ports; T1911 extends aggregate
shape/runtime coverage. T1916 qualifies domain live reads and reset isolation;
shared child writes remain owned separately.

No hardware reset means no invented initialization. T1901/T1902 keep clock-only
Verilog controls and explicit VHDL refusal: `VHDL::_split_if_else_assignments`
requires a reset-bearing process. `.36` owns extension after the SV IAL
prerequisite. Generic widths and optional presence remain separate extensions.
