---
id: direct-vhdl-generic-consumer
title: Direct VHDL generic conversion and canonical composition preparation are distinct consumers
answers:
  - "where do direct VHDL module generic defaults currently come from?"
  - "which existing VHDL helper owns canonical natural generic arithmetic?"
date: 2026-10-27
status: current
tags: [vhdl, parameters, generics, lowering]
evidence: perl/FSM/HDL/FlattenedDT/Backend/VHDL.pm; perl/FSM/Backend/VHDL/CompositionParameterEmitter.pm; perl/FSM/Backend/VHDL/ParameterBindingEmitter.pm; t/2150-shared-vhdl-parameter-binding-renderer.t; t/2136-composition-vhdl-natural-generics.t
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/2150-shared-vhdl-parameter-binding-renderer.t t/2136-composition-vhdl-natural-generics.t t/2138-composition-vhdl-scalar-emission.t
---

Direct VHDL generation first emits SystemVerilog, normalizes generated names
and parses parameter declarations from that text. Its standalone converter
supports the existing bounded static literal/integer-expression surface.
That path does not consume the Core's canonical scoped default bindings.

CompositionParameterEmitter prepares canonical `natural` defaults and actuals,
now delegating the scalar/arithmetic walk and primitive checks to shared
`FSM::Backend::VHDL::ParameterBindingEmitter`. The shared helper admits explicit
direct-module/composition-top environments; the wrapper retains composition-top
scope, case-insensitive structural namespaces and child-declaration checks.
Direct source preparation and converter integration remain `.3.2.5.2`/`.3`;
the standalone converter and existing static profile retain their contracts.
