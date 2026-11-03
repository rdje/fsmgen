---
id: vhdl-unsigned-comparison-literals
title: Unsigned comparison literals preserve widths and backend result types
answers:
  - "why did APB completer HDL verification report WIDTHEXPAND?"
  - "why did VHDL dynamic-wait counter comparisons fail GHDL analysis?"
  - "how are unsigned vector and sized literal comparisons normalized for VHDL?"
  - "how are VHDL comparison booleans assigned to scalar or vector logic outputs?"
date: 2026-11-03
status: current
tags: [vhdl, systemverilog, comparison, literals, width, runtime]
evidence: perl/FSM/Synthesis/EnableGraph/ASTSupport.pm; t/208-enable-graph-ast-support.t; perl/FSM/HDL/FlattenedDT/Backend/VHDL.pm; t/1909-isf-dynamic-wait-count-predicates.t; t/1910-vhdl-unsigned-comparison-literals.t; t/1420-vhdl-direct-backend-scaffold.t; t/1543-direct-vhdl-reduction-expression-readiness.t; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/{208,1910,1420,1543}-*.t && ./bin/fsmgen --quiet --strict --verify-hdl ppif/apb_completer.ppif
---

VHDL formerly emitted character literals beside vectors, wrapped only concurrent
equality booleans, and left relational/procedural booleans ill-typed. Unequal std_logic_vector lengths could miscompare lexicographically despite analysis.
Unsigned vector/sized integer pairs now extend to their maximum width in either
order, validating the original literal first; wider literals extend the signal,
never truncate. Signed normalization stays outside this conversion. Result values
are destination-typed zero/one through shared emission; conditions stay boolean
and declaration-aware reduction coercion preserves.

T1910 checks GHDL integer truth for narrow/wide/equal widths, scalars, reversed
operands and wider logic destinations. T1909 scalar-count timing/snapshot passes
without TODOs. These require configured GHDL; skips qualify no runtime. General
CLI --verify-hdl GHDL remains deferred.

SV comparisons explicitly zero-extend narrower unsigned sized integers beside
fixed named signals/static slices. Assignment analysis covers signals absent from module membership. AST/declaration widths preserve; symbolic,
unknown, unsized, X/Z, signed and wider literal rendering stays outside this repair.
T208 checks truth/controls; APB target verification uses no warning suppression. Signed markers: PUBLICATION-REGRESSION-REPAIRS.39 (P2).
