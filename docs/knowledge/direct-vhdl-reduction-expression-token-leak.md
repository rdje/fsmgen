---
id: direct-vhdl-reduction-expression-token-leak
title: Historical direct VHDL unary-reduction token leak in named-drive enables
answers:
  - "does direct VHDL lower unary reduction OR expressions?"
  - "why does named-drive VHDL contain a vertical bar before drive_start?"
  - "is named-drive priority VHDL-qualified?"
  - "what owns the direct VHDL reduction expression defect?"
  - "does VHDL generation success prove syntactically valid VHDL?"
date: 2026-07-30
status: historical
tags: [vhdl, backend, reduction, expression, named-drive, defect, validation]
evidence: docs/decisions/0023-vhdl-generation-success-is-not-reduction-expression-validation.md; docs/tasks/DIRECT-VHDL-REDUCTION-EXPRESSION-LOWERING.md; docs/DIRECT_VHDL_REDUCTION_EXPRESSION_BEHAVIOR.md; docs/ISF_RULE_TRANSACTION_NAMED_DRIVE_PRIORITY_CONTRACT_SELECTION.md; perl/FSM/HDL/FlattenedDT/Backend/VHDL.pm; t/data/isf_rule_transaction_named_drive_priority_probe.isf; t/1542-isf-rule-transaction-named-drive-priority-readiness.t; t/1543-direct-vhdl-reduction-expression-readiness.t
reverify: prove -Iperl t/1542-isf-rule-transaction-named-drive-priority-readiness.t t/1543-direct-vhdl-reduction-expression-readiness.t; command -v ghdl || true
---

Before `DIRECT-VHDL-REDUCTION-EXPRESSION-LOWERING.2`, the direct VHDL scaffold
accepted a scheduled named-drive FSM but emitted
`drive_zero_en and (|drive_zero_start)`. The prefix `|` was a SystemVerilog
unary reduction token, not valid VHDL expression syntax.

Root cause is `_sv_expr_to_vhdl`: it translates spaced binary `|` to `or` but
has no unary reduction-expression translation or fail-closed guard. The same
probe generates SystemVerilog and Verilog; Icarus 13.0 compiles the Verilog.
No `ghdl`, `nvc`, or `vcom` is installed, and the repository's external VHDL
validation lane remains deferred.

Generation success is therefore not VHDL qualification for this shape. Parent
selector `.831` chose the independent
`DIRECT-VHDL-REDUCTION-EXPRESSION-LOWERING` audit and repair; clean selector
commit `5f904d2d2` activated the no-behavior audit before the later repair.

Completed audit `.1` proves the original named-drive operand is declared
scalar and selects proposed `.2`: positive scalar unary OR/AND/XOR becomes
identity and complemented scalar reduction becomes VHDL `not`. Implementation
preservation proved blanket vector rejection would regress AMBA/APB paths, so
completed `.2` instead emits required-only `std_logic` vector folds while
keeping ranges/unresolved/compound forms fail-closed. t1542/t1543 now prove the
named-drive output is token-free. No external VHDL compiler claim is implied.
