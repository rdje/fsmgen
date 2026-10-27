---
id: direct-vhdl-generic-consumer
title: Direct VHDL generic conversion and canonical composition preparation are distinct consumers
answers:
  - "where do direct VHDL module generic defaults currently come from?"
  - "which existing VHDL helper owns canonical natural generic arithmetic?"
date: 2026-10-27
status: current
tags: [vhdl, parameters, generics, lowering]
evidence: perl/FSM/HDL/FlattenedDT/Backend/VHDL.pm; perl/FSM/Backend/VHDL/CompositionParameterEmitter.pm; perl/FSM/Backend/VHDL/ParameterBindingEmitter.pm; t/2150-shared-vhdl-parameter-binding-renderer.t; t/2154-direct-vhdl-generic-integration.t; t/2136-composition-vhdl-natural-generics.t
reverify: rg -n 'generate_systemverilog|_normalize_generated_vhdl_identifiers|_parse_generics|ParameterBindingEmitter|_captured_parameter_environment' perl/FSM/HDL/FlattenedDT/Backend/VHDL.pm perl/FSM/Backend/VHDL/CompositionParameterEmitter.pm perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ScaffoldEmitter.pm
---

Direct VHDL generation first emits SystemVerilog, normalizes generated names
and parses parameter declarations from that text. Its standalone converter
supports the existing bounded static literal/integer-expression surface.
The generator now supplies the Core module through a private source-aware
conversion path. After parsing actual normalized names/declarations, it joins
DirectParameterEmitter's proved natural plan with the static rows. Only the
standalone raw-text API lacks the Core environment and retains the old profile.

CompositionParameterEmitter prepares canonical `natural` defaults and actuals,
now delegating the scalar/arithmetic walk and primitive checks to shared
`FSM::Backend::VHDL::ParameterBindingEmitter`. The shared helper admits explicit
direct-module/composition-top environments; the wrapper retains composition-top
scope, case-insensitive structural namespaces and child-declaration checks.
Direct natural/static declaration preparation is now implemented separately
by DirectParameterEmitter; `direct-vhdl-parameter-profiles` owns its contract.
Completed `.3.2.5.3` activates that plan for direct generation; standalone
conversion and unrelated static defaults retain their contracts. T2154 and
native supported/refused controls qualify the integration; full override,
external/runtime/transport verification remains .6.

Generated identifiers are normalized before the direct converter parses the
module and port/signal declarations. New generic preparation must take actual
target namespace evidence from that backend boundary. Core signal/system
getters do not enumerate backend-owned intermediates or generated type names;
they cannot substitute for the target namespace. Captured source-environment
validation now lives in ParameterDefaultEnvironmentSupport; the
`direct-parameter-default-environment` card owns that contract. Direct VHDL
namespace/profile preparation consumes the actual backend target view, with
source ownership kept independent of target identifier mapping.
