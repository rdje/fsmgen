---
id: composition-scalar-binding-renderer
title: Canonical scalar composition rendering preserves scoped parameter names
answers:
  - "where does canonical scalar composition binding rendering live?"
  - "does scalar composition expression rendering enable parameterized HDL plans?"
  - "where is scalar top declaration order prepared?"
date: 2026-10-26
status: current
tags: [composition, parameters, lowering, verilog]
evidence: perl/FSM/Backend/VerilogFamily/CompositionBindingEmitter.pm; perl/FSM/Backend/VerilogFamily/CompositionParameterEmitter.pm; t/2132-composition-scalar-binding-renderer.t; t/2133-composition-top-declaration-lowering.t
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/2132-composition-scalar-binding-renderer.t t/2133-composition-top-declaration-lowering.t t/2134-composition-scalar-structural-emission.t t/2135-composition-symbolic-port-ranges.t
---

`CompositionBindingEmitter` renders scoped scalar bindings as text and ordered
references, retaining parameter names. Static scalars become literals; raw
expressions and aggregates refuse. `CompositionParameterEmitter` orders defaults
by canonical dependencies, with earliest-ready authored ties. Module, port, net,
instance and collected typedef names reserve the namespace; validation widths
never size parameter declarations.

The structural emitter requires a matching captured environment. T2134 covers
actual source/child/Plan/IR. `CompositionWidthEmitter` checks scope and ordered
lookups, retains one-bit-default parameter ranges and ignores port width caches
(T2135). Source admission, VHDL parameters, typed tops and symbolic aggregate
bindings stay guarded; existing static aggregate profiles are unchanged.
See the [composition reference](../book/src/05-composition-basics.md).
