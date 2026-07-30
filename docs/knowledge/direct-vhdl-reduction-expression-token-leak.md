---
id: direct-vhdl-reduction-expression-token-leak
title: Direct VHDL leaks SystemVerilog unary reduction syntax for named-drive enables
answers:
  - "does direct VHDL lower unary reduction OR expressions?"
  - "why does named-drive VHDL contain a vertical bar before drive_start?"
  - "is named-drive priority VHDL-qualified?"
  - "what owns the direct VHDL reduction expression defect?"
  - "does VHDL generation success prove syntactically valid VHDL?"
date: 2026-07-30
status: current
tags: [vhdl, backend, reduction, expression, named-drive, defect, validation]
evidence: docs/decisions/0023-vhdl-generation-success-is-not-reduction-expression-validation.md; docs/tasks/DIRECT-VHDL-REDUCTION-EXPRESSION-LOWERING.md; docs/ISF_RULE_TRANSACTION_NAMED_DRIVE_PRIORITY_CONTRACT_SELECTION.md; perl/FSM/HDL/FlattenedDT/Backend/VHDL.pm; t/data/isf_rule_transaction_named_drive_priority_probe.isf
reverify: rg -n '_sv_expr_to_vhdl|s/\\s\+\\\\\|\\s\+/' perl/FSM/HDL/FlattenedDT/Backend/VHDL.pm; command -v ghdl || true
---

The direct VHDL scaffold currently accepts a scheduled named-drive FSM but
emits `drive_zero_en and (|drive_zero_start)`. The prefix `|` is a
SystemVerilog unary reduction token, not valid VHDL expression syntax.

Root cause is `_sv_expr_to_vhdl`: it translates spaced binary `|` to `or` but
has no unary reduction-expression translation or fail-closed guard. The same
probe generates SystemVerilog and Verilog; Icarus 13.0 compiles the Verilog.
No `ghdl`, `nvc`, or `vcom` is installed, and the repository's external VHDL
validation lane remains deferred.

Generation success is therefore not VHDL qualification for this shape.
Active task `DIRECT-VHDL-REDUCTION-EXPRESSION-LOWERING` owns the exact audit
and repair independently from named-drive priority lowering. Parent selector
`.831` chooses `.1`, and clean selector commit `5f904d2d2` activates that
no-behavior audit without changing the leak or any generated output.
