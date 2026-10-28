---
id: sv-intermediate-truthiness-width
title: SystemVerilog intermediate truthiness uses recorded intermediate widths
answers:
  - "how does FSMGen render multi-bit intermediate equality to zero?"
  - "why should multi-bit intermediates not render as bare negation?"
  - "what did the .219 renderer-width fix cover?"
  - "how are scalar reduction intermediate origins captured?"
  - "how are multi-bit generated intermediate signals treated in truthiness?"
date: 2026-10-28
status: current
tags: [systemverilog, hdl, ast, width, intermediate-signal, codegen]
evidence: t/2190-scalar-intermediate-capture.t; perl/FSM/Backend/VerilogFamily/DeclarationCapture.pm; docs/audits/scalar-intermediate-capture-20261028.json.gz; perl/FSM/Synthesis/EnableGraph/ASTSupport.pm; t/208-enable-graph-ast-support.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/2190-scalar-intermediate-capture.t t/208-enable-graph-ast-support.t
---

Render-time ASTSupport uses recorded intermediate widths: multi-bit zero
comparison `(~|sum_expr)`; nonzero keeps sized equality when needed; one-bit
forms stay compact. This .219 lookup adds no recursive hot-path width inference.

Collector target_intermediates records actual declarations and selected
assign text, or {} for missing assigns. Whole-SignalRef XOR/AND/OR origins need
agreeing defining/runtime ASTs and emitted text, width1 and a declared operand.
Stored-only/stale/computed shapes gain no proof. Input/output detach; empty
sets preserve old snapshots. Source unsigned/type and symbolic VHDL proof remain
separate.
