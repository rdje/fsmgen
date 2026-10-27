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
reverify: rg -n 'generate_systemverilog|_normalize_generated_vhdl_identifiers|_parse_generics|ParameterBindingEmitter|_captured_parameter_environment' perl/FSM/HDL/FlattenedDT/Backend/VHDL.pm perl/FSM/Backend/VHDL/CompositionParameterEmitter.pm perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ScaffoldEmitter.pm
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

Generated identifiers are normalized before the direct converter parses the
module and port/signal declarations. New generic preparation must take actual
target namespace evidence from that backend boundary. Core signal/system
getters do not enumerate backend-owned intermediates or generated type names;
they cannot substitute for the target namespace. Captured source-environment
validation now lives in ParameterDefaultEnvironmentSupport; the
`direct-parameter-default-environment` card owns that contract. Direct VHDL
namespace/profile preparation still consumes the actual backend target view.
