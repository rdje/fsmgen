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
evidence: perl/FSM/Scheduler/ISF/LoweringIR.pm; t/1900-isf-declared-output-preservation.t; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md; docs/book/src/13a-actor-interface.md
reverify: FSMGEN_RESET_GHDL=.artifacts/cache/providers/ghdl/6.0.0/llvm-jit-tool/ghdl-llvm-jit-6.0.0-macos15-aarch64/bin/ghdl scripts/run_with_ram_guard.sh -- prove -Iperl t/1900-isf-declared-output-preservation.t
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
No runtime value is claimed for an undriven output, and no assignment is added.

Reset-only output behavior remains a separate gap owned by immediate leaf
`.35`: replace the retained baseline output with
`(output AWMECID (width 16) (reset 3))`. Native strict admission succeeds and
the FSM retains that reset, but generated SystemVerilog can have no reset
assignment for the otherwise undriven port. T1900 qualifies interface identity,
not this authored reset's runtime behavior. The task records the exact
reproduction and required behavior repair. Generic widths and optional
presence likewise remain separately owned extensions.
