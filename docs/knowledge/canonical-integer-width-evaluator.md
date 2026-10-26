---
id: canonical-integer-width-evaluator
title: Direct width arithmetic has one reusable canonical evaluator
answers:
  - "where is the canonical bounded integer-width evaluator?"
  - "how does explicit parameter width selection avoid static namespace borrowing?"
date: 2026-10-26
status: current
tags: [widths, parameters, composition]
evidence: perl/FSM/WidthExpressionSupport.pm; t/2128-shared-integer-width-evaluator.t
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/2128-shared-integer-width-evaluator.t t/2111-ial0-parameter-width-selection.t t/294-scalar-width-support.t t/50-language-contract-size-section-boundary.t
---

[WidthExpressionSupport](../../perl/FSM/WidthExpressionSupport.pm) owns the
existing direct-parser integer arithmetic. Parser inherits its methods and
supplies the existing SignalManager namespaces through explicit hooks.
The helper's ordinary-symbol callback resolves bare symbols, including those
inside infix scalar payloads. Its declared-parameter callback alone resolves
`(param NAME)`. It preserves existing aliases, arity, precedence, scalar-only
payloads, nonnegative intermediate results and positive final widths.

Composition verbose Port expressions now reuse it after import/default
resolution. Explicit `(param NAME)` keeps declaration identity separate from
bare static operands; detached `width_contract` retains scope/source/lookups.
The declaration-only test is `t/2129-composition-port-width-expressions.t`.
IR/schema propagation is owned by `.2.3.3.4.1.3.2.2` in
`ISF-REDUCTION-DELIVERY`; symbolic plans/HDL and full qualification remain pending. The
[book](../book/src/14k-isf-language-and-scheduling.md) retains that boundary.
