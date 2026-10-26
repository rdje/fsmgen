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

This is preparation for composition reuse, not new source admission. Port
integration is owned by `ISF-REDUCTION-DELIVERY.2.3.3.4.1.3.2`; symbolic source
planning/emission and full qualification remain separately pending. The
[book](../book/src/14k-isf-language-and-scheduling.md) retains that boundary.
