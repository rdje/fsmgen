---
id: direct-vhdl-reduction-expression-readiness-audit
title: Direct VHDL reduction audit selects scalar identity and vector fail-closed handling
answers:
  - "what does DIRECT-VHDL-REDUCTION-EXPRESSION-LOWERING.1 select?"
  - "how should direct VHDL handle unary OR AND XOR reductions?"
  - "why is scalar unary reduction an identity?"
  - "why will direct VHDL reject vector reductions?"
  - "does FSM source accept one-operand OR AND XOR?"
  - "what happens to complemented reductions like (~|VECTOR)?"
  - "which test characterizes direct VHDL reduction expressions?"
date: 2026-07-30
status: current
tags: [vhdl, backend, reduction, expression, scalar, vector, fail-closed, audit]
evidence: docs/DIRECT_VHDL_REDUCTION_EXPRESSION_READINESS_AUDIT.md; docs/tasks/DIRECT-VHDL-REDUCTION-EXPRESSION-LOWERING.md; docs/decisions/0023-vhdl-generation-success-is-not-reduction-expression-validation.md; perl/FSM/HDL/FlattenedDT/Backend/VHDL.pm; perl/FSM/Synthesis/EnableGraph/ASTSupport.pm; perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm; t/1543-direct-vhdl-reduction-expression-readiness.t; t/1542-isf-rule-transaction-named-drive-priority-readiness.t
reverify: prove -Iperl t/1543-direct-vhdl-reduction-expression-readiness.t; rg -n '_render_truthiness_value|_render_truthiness_negation|_sv_expr_to_vhdl|_sv_condition_to_vhdl|requires at least 2 operands' perl/FSM/Synthesis/EnableGraph/ASTSupport.pm perl/FSM/HDL/FlattenedDT/Backend/VHDL.pm perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm t/1543-direct-vhdl-reduction-expression-readiness.t
---

Audit `.1` selects `.2` to lower positive scalar unary OR/AND/XOR reductions
as identity, lower complemented scalar reductions as VHDL `not`, and reject
vector, range-slice, unresolved, compound, or malformed reductions before
emission. The selected scalar operands are declaration-proven identifiers and
static bit selects only.

Public `.fsm` one-operand `|`, `&`, and `^` forms already fail the n-ary arity
gate and remain unchanged. The actual named-drive operand is declared scalar,
so identity fixes the observed `(|drive_zero_start)` without requiring a
vector-reduction language feature. Public vector truthiness currently leaks
both `(|VECTOR)` and `(~|VECTOR)`; `.2` will replace silent invalid output with
a targeted direct-scaffold rejection.

No VHDL compiler is installed, so the audit does not select or qualify native
VHDL vector-reduction syntax. t1543 durably characterizes the current scalar/
vector pipeline, six-case converter matrix, and public parser boundary. The
audit changes no behavior; `.2` requires a separate clean activation commit.
