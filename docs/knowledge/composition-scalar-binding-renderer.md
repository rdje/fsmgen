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
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/2132-composition-scalar-binding-renderer.t t/2133-composition-top-declaration-lowering.t t/2134-composition-scalar-structural-emission.t
---

`CompositionBindingEmitter` renders scoped canonical bindings as text and ordered
parameter references, preserving names rather than validation values. Static
scalars normalize to literals; raw expression text and aggregates refuse.

`CompositionParameterEmitter::lower_declarations` orders scalar defaults by
canonical dependencies, selecting the earliest ready authored declaration. It
reserves actual module, port, net, instance and collected typedef names. Cached
widths never fix parameter sizes.

The Verilog-family structural emitter consumes these helpers with a matching
captured environment. Actual source, child validation and captured Plan/IR are
checked by T2134. Discovery names this prepared scalar subset; source admission,
width contracts, VHDL parameters, explicit typed tops and symbolic aggregate
bindings remain guarded. Existing static aggregate profiles are unchanged.
See the [composition reference](../book/src/05-composition-basics.md).
