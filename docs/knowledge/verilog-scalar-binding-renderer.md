---
id: verilog-scalar-binding-renderer
title: Verilog-family scalar rendering shares explicit source scopes
answers:
  - "where is shared Verilog-family scalar binding rendering implemented?"
  - "can canonical direct Core bindings be rendered before header integration?"
date: 2026-10-27
status: current
tags: [verilog, parameters, binding, lowering]
evidence: perl/FSM/Backend/VerilogFamily/ParameterBindingEmitter.pm; perl/FSM/Backend/VerilogFamily/CompositionBindingEmitter.pm; t/2146-shared-scalar-binding-renderer.t
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/2146-shared-scalar-binding-renderer.t t/2132-composition-scalar-binding-renderer.t t/2133-composition-top-declaration-lowering.t
---

The shared target helper consumes canonical scalar bindings with explicit
direct-module or composition-top scope and complete declaration membership.
It returns selected names, parenthesized operators, immutable static selections
and ordered repeated dependencies. Validation-cache values do not replace roots.
`text` retains the existing canonical scalar kind, including numeric decimal
statics, for interpolation into HDL. This private result introduces no public
serialized schema.

The composition wrapper keeps its narrower scope and diagnostics; complete
existing composition expression/declaration products retain their JSON kinds.
Foreign scopes, incomplete declarations, recursive trees, aggregate/path and
raw scalar-expression profiles refuse. Direct header integration, generic
ranges and full external/runtime qualification remain separate consumers.
