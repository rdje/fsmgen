---
id: vhdl-unsigned-comparison-literals
title: Direct VHDL comparisons preserve unsigned widths and logic result types
answers:
  - "why did VHDL dynamic-wait counter comparisons fail GHDL analysis?"
  - "how are unsigned vector and sized literal comparisons normalized for VHDL?"
  - "how are VHDL comparison booleans assigned to scalar or vector logic outputs?"
date: 2026-09-27
status: current
tags: [vhdl, comparison, literals, width, runtime]
evidence: perl/FSM/HDL/FlattenedDT/Backend/VHDL.pm; t/1909-isf-dynamic-wait-count-predicates.t; t/1910-vhdl-unsigned-comparison-literals.t; t/1420-vhdl-direct-backend-scaffold.t; t/1543-direct-vhdl-reduction-expression-readiness.t; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: scripts/run_with_ram_guard.sh prove -Iperl t/1910-vhdl-unsigned-comparison-literals.t t/1420-vhdl-direct-backend-scaffold.t t/1543-direct-vhdl-reduction-expression-readiness.t
---

The direct backend previously converted a one-bit sized constant into a
character literal even when its comparison operand was a vector. It also
wrapped only concurrent equality results as std_logic, leaving relational and
procedural comparison booleans ill-typed. Dynamic-wait GHDL analysis exposed
both paths. Operand widths additionally matter numerically: unequal-length
std_logic_vector comparison is lexicographic, so a narrower data vector could
compare incorrectly with a wider literal even when analysis succeeded.

Unsigned vector/sized numeric-literal pairs now extend to their maximum width,
in either operand order. The original literal is validated before extension;
a wider literal extends the signal instead of truncating the literal. Signed
operand normalization is outside this specific conversion. Comparison results
use typed zero/one values for their destination through shared expression
emission, and condition contexts keep boolean results. Existing declaration-
aware reduction conditions retain their prior boolean coercion.

T1910 compares GHDL outputs with integer truth tables for narrow/wide/equal
widths, scalar controls, reversed operands and wider logic destinations. T1909
now passes its original scalar-count GHDL timing and snapshot oracle without
TODOs. These tests require the configured GHDL provider; skipped runs do not
qualify runtime behavior. The general CLI --verify-hdl GHDL lane remains a
separate deferred surface.
