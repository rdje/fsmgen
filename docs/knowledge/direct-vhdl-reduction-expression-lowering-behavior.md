---
id: direct-vhdl-reduction-expression-lowering-behavior
title: Direct VHDL lowers scalar and vector unary reductions without foreign tokens
answers:
  - "does direct VHDL lower unary OR AND XOR reductions?"
  - "how does direct VHDL reduce a std_logic_vector?"
  - "does direct VHDL support complemented reductions?"
  - "does direct VHDL reduce signed vectors?"
  - "why does FSMGen emit fsmgen_direct_vhdl_reduce_or?"
  - "does named-drive VHDL still contain (|drive_zero_start)?"
  - "which unary reduction operands still fail in direct VHDL?"
  - "does reduction lowering widen the public FSM grammar?"
date: 2026-10-22
status: current
tags: [vhdl, backend, reduction, expression, scalar, vector, fold, fail-closed]
evidence: docs/DIRECT_VHDL_REDUCTION_EXPRESSION_BEHAVIOR.md; docs/DIRECT_VHDL_REDUCTION_EXPRESSION_READINESS_AUDIT.md; docs/tasks/DIRECT-VHDL-REDUCTION-EXPRESSION-LOWERING.md; perl/FSM/HDL/FlattenedDT/Backend/VHDL.pm; t/1542-isf-rule-transaction-named-drive-priority-readiness.t; t/1543-direct-vhdl-reduction-expression-readiness.t; t/1420-vhdl-direct-backend-scaffold.t; t/386-hdl-generator-facade-target-language-boundary-audit.t
reverify: scripts/run_with_ram_guard.sh prove -Iperl t/1542-isf-rule-transaction-named-drive-priority-readiness.t t/1543-direct-vhdl-reduction-expression-readiness.t t/1420-vhdl-direct-backend-scaffold.t t/386-hdl-generator-facade-target-language-boundary-audit.t t/404-hdl-generator-facade-target-language-shape-boundary-audit.t
---

Direct VHDL recognizes generated parenthesized unary OR/AND/XOR before generic
rewrites. Declared scalars and in-range static bit selects lower by identity or
complement. Declared vectors lower through backend-owned `std_logic` fold
helpers; signed vectors cast explicitly to `std_logic_vector`, and complemented
forms apply `not` to the helper result.

Only required helpers are emitted. They fold OR/XOR from `'0'` and AND from
`'1'`, preserving `std_logic` unknown propagation without using unqualified
native vector-reduction syntax. Helper-name collisions, ranges, invalid
selects, unresolved/compound/malformed operands, and residual reduction tokens
fail closed before output.

The real named-drive positive and complemented scalar reductions are now
token-free. Existing AMBA `HRESP` and APB `wait_ctr`/`addr_q` vector truthiness
remains supported through the helpers. Decision `0117` now admits declared
unary source forms. Ranges still refuse here; decision `0023` withholds external
VHDL compile/runtime qualification; no authoritative compiler was available.

Runtime revalidation on Darwin requires the separately qualified opt-in; a
skipped T1542 is not executable evidence. Retain the RAM guard defaults.
