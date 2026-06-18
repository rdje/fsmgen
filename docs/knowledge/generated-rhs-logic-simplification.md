---
id: generated-rhs-logic-simplification
title: Generated HDL RHS expressions are simplified from the AST before emission
answers:
  - "why does generated HDL omit redundant & 1'b1 terms?"
  - "where is generated RHS logic simplification implemented?"
  - "are generated-enable RHS ASTs simplified before rendering?"
  - "does generated RHS simplification handle vector or multi-bit bitwise expressions?"
  - "does direct VHDL inherit generated RHS simplification?"
  - "does structural_rtl_ir store simplified generated-enable RHS ASTs?"
date: 2026-06-18
status: current
tags: [generated-hdl, rhs-expression, logic-simplification, vector-logic, structural-rtl-ir, vhdl]
evidence: perl/FSM/Synthesis/EnableGraph/ASTSupport.pm; perl/FSM/Synthesis/EnableGraph/CaptureSupport.pm; perl/FSM/IR/StructuralRTLIRBuilder.pm; t/208-enable-graph-ast-support.t; t/207-enable-graph-capture-support.t; t/206-enable-graph-enable-support.t; t/1333-direct-structural-rtl-ir-projection.t; t/163-forward-structural-rtl-ir-surface.t; t/624-hdl-generator-stateful-direct-structural-rtl-ir-alias-boundary-audit.t; t/1420-vhdl-direct-backend-scaffold.t; docs/book/src/09-generated-hdl-debugging-and-inspection.md; docs/tasks/RHS-LOGIC-SIMPLIFICATION-FRONTIER.md
reverify: env -u PERL5LIB prove -Iperl t/208-enable-graph-ast-support.t t/207-enable-graph-capture-support.t t/206-enable-graph-enable-support.t t/1333-direct-structural-rtl-ir-projection.t t/163-forward-structural-rtl-ir-surface.t t/624-hdl-generator-stateful-direct-structural-rtl-ir-alias-boundary-audit.t t/1420-vhdl-direct-backend-scaffold.t
---

Generated HDL RHS expressions pass through
`FSM::Synthesis::EnableGraph::ASTSupport::simplify_logic_ast` before
SystemVerilog text emission. The pass is AST-based and width-conservative: it
removes proven boolean identities such as `enable & 1`, complements, double
negation, absorption, and consensus forms. It also simplifies vector and
multi-bit bitwise RHS expressions when operand widths and literal masks prove
the replacement preserves both value and expression width, including
same-width all-one/all-zero masks, vector self-XOR, vector complement pairs,
double bitwise negation, absorption, and consensus patterns. Width-changing
mask cases such as `BUS1 & 1'b1` remain preserved because they are not vector
identities.

Direct generated-enable `structural_rtl_ir.assignment_records[]` store the
same simplified RHS AST that is rendered into the assignment text. The direct
VHDL scaffold inherits the cleaner RHS through the shared direct
SystemVerilog-generation path before its VHDL conversion boundary.
Captured assignment RHS metadata now routes through the same shared AST
simplifier before falling back to raw `to_systemverilog` rendering.
