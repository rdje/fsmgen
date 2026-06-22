---
id: sv-intermediate-truthiness-width
title: SystemVerilog intermediate truthiness uses recorded intermediate widths
answers:
  - "how does FSMGen render multi-bit intermediate equality to zero?"
  - "why should multi-bit intermediates not render as bare negation?"
  - "what did the .219 renderer-width fix cover?"
  - "how are multi-bit generated intermediate signals treated in truthiness?"
date: 2026-06-22
status: current
tags: [systemverilog, hdl, ast, width, intermediate-signal, codegen]
evidence: perl/FSM/Synthesis/EnableGraph/ASTSupport.pm; t/208-enable-graph-ast-support.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md
reverify: rg -n 'intermediate_signal_width|_intermediate_signal_width|multi-bit intermediate|~\\|sum_expr|AST support renders multi-bit intermediate equals-zero' perl/FSM/Synthesis/EnableGraph/ASTSupport.pm t/208-enable-graph-ast-support.t docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md
---

FSMGen's SystemVerilog AST support now consults recorded intermediate signal
width metadata when deciding whether an intermediate expression is one bit or
multi-bit at render time.

For a multi-bit intermediate, equality to zero renders through a reduction-zero
form such as `(~|sum_expr)` instead of a one-bit logical negation like
`!sum_expr`. Equality to a nonzero value remains an explicit sized equality
when that is required to preserve width. One-bit intermediates still use the
existing compact boolean forms.

This is a render-time metadata lookup only. It does not introduce recursive
runtime width inference in the hot HDL-generation path.
