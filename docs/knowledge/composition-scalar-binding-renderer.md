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
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/2132-composition-scalar-binding-renderer.t t/2133-composition-top-declaration-lowering.t t/2134-composition-scalar-structural-emission.t t/2135-composition-symbolic-port-ranges.t t/2136-composition-vhdl-natural-generics.t t/2138-composition-vhdl-scalar-emission.t t/2139-composition-vhdl-port-ranges.t
---

`CompositionBindingEmitter` retains scoped scalar names/references; static
scalars become literals. Raw text/aggregates refuse. `CompositionParameterEmitter`
orders defaults by dependencies and earliest-ready authored ties, reserving
structural/typedef names. `CompositionWidthEmitter` checks scope/ordered lookups,
retaining one-bit-default ranges independently of numeric caches (T2132-T2135).

The VHDL helper/emitter emits canonical `natural` defaults with bounded arithmetic and case-insensitive
names (T2136). Integer child actuals retain selected names (T2138); symbolic sized/aggregate
children refuse; captured VHDL arithmetic ranges retain names (T2139). Source admission,
typed tops and symbolic aggregate bindings stay pending; static aggregate
profiles are unchanged. See the [composition reference](../book/src/05-composition-basics.md).
