---
id: canonical-integer-width-evaluator
title: Direct width arithmetic has one reusable canonical evaluator
answers:
  - "where is the canonical bounded integer-width evaluator?"
  - "how does explicit parameter width selection avoid static namespace borrowing?"
date: 2026-10-26
status: current
tags: [widths, parameters, composition]
evidence: perl/FSM/WidthExpressionSupport.pm; t/2128-shared-integer-width-evaluator.t; t/2131-composition-port-width-public-contract.t
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/2128-shared-integer-width-evaluator.t t/2129-composition-port-width-expressions.t t/2130-composition-port-width-plan-snapshots.t t/2131-composition-port-width-public-contract.t
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
Plan capture and getters detach expression Ports so later source retries cannot
change widths beside an earlier captured environment (test `t/2130-composition-port-width-plan-snapshots.t`).
Optional width contracts now survive structural ports, IntentHIR/common signal
analysis and plan snapshots. CompositionParameterContract advertises exact
paths/keys; mismatched supplied IR and non-JSON snapshot references refuse.
Both structural emitters call the shared pending-binding guard, which refuses
known width contracts even without a top environment. Symbolic plans/HDL and
full qualification remain separately pending in `ISF-REDUCTION-DELIVERY`. The
[book](../book/src/14k-isf-language-and-scheduling.md) retains that boundary.
