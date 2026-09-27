---
id: isf-bit-helper-literal-width-precedence
title: Bit helpers honor formal scope and refuse unresolved type placeholders
answers:
  - "how do bit helpers resolve transaction formal widths?"
  - "why does clear-bit reject a type alias or parameter width?"
  - "can a shadowing formal borrow an actor width during bit desugaring?"
  - "why did clearing one bit of a typed output generate a zero mask?"
date: 2026-09-27
status: current
tags: [isf, bits, widths, scope, parser, formals]
evidence: perl/FSM/Adapter/ISF/Parser.pm; t/1926-isf-formal-bit-width.t; docs/audits/direct-formal-bit-width-scope-20260927.json; docs/audits/formal-bit-width-placeholder-20260927.json; docs/book/src/13e-data-manipulation.md
reverify: FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME=1 scripts/run_with_ram_guard.sh prove -Iperl t/1926-isf-formal-bit-width.t t/1401-isf-bit-ops.t t/1402-isf-bit-test.t t/1403-isf-set-field.t t/1404-isf-when-field.t t/1408-isf-rotate.t
---

Parser::_bit_op_width_map supplies the bit-operation, set-field, rotate,
bit-test and field-test desugaring passes. Lookup checks transaction local
declarations, transaction ports, actor interface ports and actor storage
variables in that order. An unresolved declaration is retained with undefined
width; it shadows outer declarations instead of borrowing their widths.

These passes precede general parameter/constant width and type finalization.
Only declared literal widths are evidence here. Interface/formal `(type ...)`
entries carry a temporary width before type finalization; that placeholder
must never determine a mask or range. Width-dependent helpers reject unresolved
type/symbolic widths. Width-independent bit masks retain existing admission
and apply range checks when a literal width is available. A genuinely omitted
formal width remains its declared one-bit default and is separately tested.

The original formal-shadow audit reverses actor/formal widths and demonstrates
both incorrect rejection and incorrect range acceptance. The type-placeholder
audit separately retains a typed output's wrong zero mask in parsed clauses
and emitted IAL0. Its original HDL runtime is not claimed. The same source now
fails at the intended declared-literal-width check, without emitting that mask.

T1926 covers the shared helper's callers, nested control flow, unresolved
actor/transaction parameter and type widths, and direct port-only plus generated
child shadowing execution. Its production HDL oracle checks repeated calls and
reset during work while preserving actor storage. It also compares complete
native/API/newline MCP reports and strict-replays every emitted IAL0 artifact.
Direct same-name actor/formal physical identities remain an independent
integration obligation under .49.2.2.3; this parser repair does not close it.

Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.4.
