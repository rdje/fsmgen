---
id: direct-vhdl-generic-consumer
title: Direct VHDL generic conversion and canonical composition preparation are distinct consumers
answers:
  - "where do direct VHDL module generic defaults currently come from?"
  - "which existing VHDL helper owns canonical natural generic arithmetic?"
date: 2026-10-27
status: current
tags: [vhdl, parameters, generics, lowering]
evidence: perl/FSM/HDL/FlattenedDT/Backend/VHDL.pm; perl/FSM/Backend/VHDL/CompositionParameterEmitter.pm; t/2136-composition-vhdl-natural-generics.t
reverify: rg -n 'generate_systemverilog|_parse_generics|_sv_parameter_default_to_vhdl|sub lower_declarations|sub _render' perl/FSM/HDL/FlattenedDT/Backend/VHDL.pm perl/FSM/Backend/VHDL/CompositionParameterEmitter.pm
---

Direct VHDL generation first emits SystemVerilog, normalizes generated names
and parses parameter declarations from that text. Its standalone converter
supports the existing bounded static literal/integer-expression surface.
That path does not consume the Core's canonical scoped default bindings.

CompositionParameterEmitter separately prepares canonical `natural` defaults
and actuals with decimal literals, aliases, captured static values and bounded
arithmetic. It validates composition-top scope and a case-insensitive target
namespace. Shared direct-source reuse is tracked by ISF-REDUCTION-DELIVERY
`.3.2.5`; implementation must preserve both existing contracts and source scope.
