---
id: composition-scalar-binding-renderer
title: Scalar composition rendering preserves scoped parameter names
answers:
  - "where does canonical scalar composition binding rendering live?"
  - "does scalar composition expression rendering enable parameterized HDL plans?"
  - "where is scalar top declaration order prepared?"
  - "where are VHDL composition natural generics prepared?"
date: 2026-10-26
status: current
tags: [composition, parameters, lowering, verilog]
evidence: docs/book/src/05-composition-basics.md; t/2136-composition-vhdl-natural-generics.t
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/2132-composition-scalar-binding-renderer.t t/2133-composition-top-declaration-lowering.t t/2134-composition-scalar-structural-emission.t t/2135-composition-symbolic-port-ranges.t t/2136-composition-vhdl-natural-generics.t
---

Verilog-family `CompositionBindingEmitter` retains scoped scalar names and
ordered references; static scalars become literals. Raw text and aggregates
refuse. `CompositionParameterEmitter` orders defaults by dependencies with
earliest-ready authored ties, reserving module/port/net/instance/typedef names.
Validation widths never size declarations. T2134 covers actual source/child/Plan/IR.
`CompositionWidthEmitter` checks scope/ordered lookups and ignores port caches,
retaining one-bit-default parameter ranges (T2135).

The VHDL `CompositionParameterEmitter` prepares canonical `natural` defaults
with case-insensitive basic-identifier namespace checks and bounded decimal
arithmetic (T2136). Actual VHDL parameter emission stays guarded. Source admission,
typed tops and symbolic aggregate bindings stay pending; static aggregate
profiles are unchanged. See the [composition reference](../book/src/05-composition-basics.md).
