---
id: sv-intermediate-truthiness-width
title: Scalar reduction origins and render-time intermediate widths
answers:
  - "how does FSMGen render multi-bit intermediate equality to zero?"
  - "why should multi-bit intermediates not render as bare negation?"
  - "what did the .219 renderer-width fix cover?"
  - "how are scalar reduction intermediate origins captured?"
  - "which scalar intermediates allow generic VHDL?"
  - "how are multi-bit generated intermediate signals treated in truthiness?"
date: 2026-10-28
status: current
tags: [systemverilog, hdl, ast, width, intermediate-signal, codegen]
evidence: t/2190-scalar-intermediate-capture.t; perl/FSM/Backend/VerilogFamily/DeclarationCapture.pm; docs/audits/direct-vhdl-scalar-intermediates-20261028.json.gz; perl/FSM/Synthesis/EnableGraph/ASTSupport.pm; t/208-enable-graph-ast-support.t; t/2191-direct-vhdl-scalar-intermediates.t
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/219[01]*.t t/208-enable-graph-ast-support.t
---

Render-time ASTSupport uses recorded widths: multi-bit zero -> `(~|sum_expr)`;
nonzero keeps sized equality when needed; scalar forms stay compact. The .219
lookup adds no recursive hot-path width inference.

Collector target_intermediates retains actual declarations and selected text,
or {} for absent assigns. Whole-SignalRef XOR/AND/OR origins require agreeing
defining/runtime ASTs and emitted text, width1 and a declared operand.
Stored-only/stale/computed shapes gain no proof. Inputs/results detach; empty
sets preserve old snapshots. Paired VHDL proves plain unsigned operands, scalar
results and exact assignments (T2191); other shapes refuse.
