---
id: generated-rhs-logic-simplification
title: Generated HDL RHS expressions are simplified from the AST before emission
answers:
  - "why does generated HDL omit redundant & 1'b1 terms?"
  - "where is generated RHS logic simplification implemented?"
  - "are generated-enable RHS ASTs simplified before rendering?"
  - "does direct VHDL inherit generated RHS simplification?"
  - "does structural_rtl_ir store simplified generated-enable RHS ASTs?"
date: 2026-06-18
status: current
tags: [generated-hdl, rhs-expression, logic-simplification, structural-rtl-ir, vhdl]
evidence: perl/FSM/Synthesis/EnableGraph/ASTSupport.pm; perl/FSM/IR/StructuralRTLIRBuilder.pm; t/208-enable-graph-ast-support.t; t/206-enable-graph-enable-support.t; t/1333-direct-structural-rtl-ir-projection.t; t/163-forward-structural-rtl-ir-surface.t; t/624-hdl-generator-stateful-direct-structural-rtl-ir-alias-boundary-audit.t; t/1420-vhdl-direct-backend-scaffold.t; docs/book/src/09-generated-hdl-debugging-and-inspection.md; docs/tasks/RHS-LOGIC-SIMPLIFICATION-FRONTIER.md
reverify: env -u PERL5LIB prove -Iperl t/208-enable-graph-ast-support.t t/206-enable-graph-enable-support.t t/1333-direct-structural-rtl-ir-projection.t t/163-forward-structural-rtl-ir-surface.t t/624-hdl-generator-stateful-direct-structural-rtl-ir-alias-boundary-audit.t t/1420-vhdl-direct-backend-scaffold.t
---

Generated HDL RHS expressions pass through
`FSM::Synthesis::EnableGraph::ASTSupport::simplify_logic_ast` before
SystemVerilog text emission. The pass is AST-based and width-conservative: it
removes proven boolean identities such as `enable & 1`, complements, double
negation, absorption, and consensus forms, while preserving vector expressions
such as `BUS1 & 1'b1` when that is not a width-safe identity.

Direct generated-enable `structural_rtl_ir.assignment_records[]` store the
same simplified RHS AST that is rendered into the assignment text. The direct
VHDL scaffold inherits the cleaner RHS through the shared direct
SystemVerilog-generation path before its VHDL conversion boundary.
