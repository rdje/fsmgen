---
id: aggregate-parameter-comparison
title: Semantic parameter and generic aggregate comparison support
answers:
  - "do aggregate parameters support equality or inequality?"
  - "can I compare aggregate +params with == or !=?"
  - "does .rtlif support aggregate generic comparison defaults?"
  - "how do aggregate comparison parameters lower to HDL?"
date: 2026-06-05
status: current
tags: [parameters, generics, aggregates, composition, hdl-lowering]
evidence: docs/book/src/04-symbols-types-and-imports.md; docs/book/src/06-composition-advanced.md; perl/FSM/ParameterValueSupport.pm; t/30-language-contract-symbol-definitions.t; t/88-rtlif-typed-port-contract.t; t/91-composition-multi-rtl-children.t; t/292-composition-generated-child-parameter-overrides.t
reverify: prove -Iperl t/30-language-contract-symbol-definitions.t t/51-language-contract-symbol-definition-boundary.t t/88-rtlif-typed-port-contract.t t/91-composition-multi-rtl-children.t t/292-composition-generated-child-parameter-overrides.t
---

Semantic parameter/generic aggregate expressions support binary `(== A B)` and
`(!= A B)` when both operands resolve to matching list/record aggregate shapes.
The comparison is folded before HDL lowering into scalar exact-width `1'b1` or
`1'b0`.

The shipped surfaces are direct `+params`, `.rtlif` defaults, external RTL
parameter/generic overrides, and generated-child parameter overrides. Mixed
scalar/aggregate operands, mismatched aggregate shapes, non-binary arity,
runtime aggregate expressions, ISF runtime aggregate expressions, and VHDL
aggregate lowering remain fail-closed or deferred. Shipped by
`COMPOSITION-TYPE-BACKLOG-EXHAUSTION.11`.
