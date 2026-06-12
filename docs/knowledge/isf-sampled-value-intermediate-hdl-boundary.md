---
id: isf-sampled-value-intermediate-hdl-boundary
title: ISF sampled-value properties stay out of combinational helper wires
answers:
  - "can sampled-value checks create combinational intermediate wires?"
  - "why is $past not emitted as an assign helper?"
  - "where are sampled-value helper chains pruned before HDL emission?"
date: 2026-06-12
status: current
tags: [isf, verification, sampled-value, hdl, systemverilog]
evidence: perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSupport.pm; perl/FSM/Pipeline/GeneratedModuleInfoBuilder.pm; t/1436-ial2-ppif-parser-cli.t; t/1411-isf-assert-emit.t; t/1412-isf-property-implication.t
reverify: prove -Iperl t/1436-ial2-ppif-parser-cli.t t/1411-isf-assert-emit.t t/1412-isf-property-implication.t
---

Sampled-value functions (`$past`, `$stable`, `$changed`, `$rose`, `$fell`) are
valid in assertion/assume/cover property text, not as unclocked combinational
helper assignments.

`GeneratedModuleInfoBuilder` renders check properties with intermediate
sampled-value signal references inlined back to their driving property AST
where needed. `ConsolidatedIntermediateSupport` prunes sampled-value
intermediate helpers and their transitive dependent helper chains before the
direct SystemVerilog backend declares wires or emits assigns.
