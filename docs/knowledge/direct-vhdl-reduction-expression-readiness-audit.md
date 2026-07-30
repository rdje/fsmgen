---
id: direct-vhdl-reduction-expression-readiness-audit
title: Direct VHDL reduction audit and preservation reconcile scalar identity with vector folds
answers:
  - "what does DIRECT-VHDL-REDUCTION-EXPRESSION-LOWERING.1 select?"
  - "how should direct VHDL handle unary OR AND XOR reductions?"
  - "why is scalar unary reduction an identity?"
  - "why did direct VHDL select vector fold helpers?"
  - "does FSM source accept one-operand OR AND XOR?"
  - "what happens to complemented reductions like (~|VECTOR)?"
  - "which test characterizes direct VHDL reduction expressions?"
date: 2026-07-30
status: current
tags: [vhdl, backend, reduction, expression, scalar, vector, fail-closed, audit]
evidence: docs/DIRECT_VHDL_REDUCTION_EXPRESSION_READINESS_AUDIT.md; docs/tasks/DIRECT-VHDL-REDUCTION-EXPRESSION-LOWERING.md; docs/decisions/0023-vhdl-generation-success-is-not-reduction-expression-validation.md; perl/FSM/HDL/FlattenedDT/Backend/VHDL.pm; perl/FSM/Synthesis/EnableGraph/ASTSupport.pm; perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm; t/1543-direct-vhdl-reduction-expression-readiness.t; t/1542-isf-rule-transaction-named-drive-priority-readiness.t
reverify: prove -Iperl t/1543-direct-vhdl-reduction-expression-readiness.t; rg -n '_render_truthiness_value|_render_truthiness_negation|_sv_expr_to_vhdl|_sv_condition_to_vhdl|requires at least 2 operands' perl/FSM/Synthesis/EnableGraph/ASTSupport.pm perl/FSM/HDL/FlattenedDT/Backend/VHDL.pm perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm t/1543-direct-vhdl-reduction-expression-readiness.t
---

Audit `.1` selected scalar identity/complement and initially selected vector
rejection. The first `.2` preservation gate proved rejection would regress
shipped AMBA/APB direct VHDL, so the final reconciled contract uses
backend-owned `std_logic` folds for declared vectors and rejects only range,
invalid-select, unresolved, compound, malformed, residual, or helper-collision
shapes.

Public `.fsm` one-operand `|`, `&`, and `^` forms already fail the n-ary arity
gate and remain unchanged. The actual named-drive operand is declared scalar,
so identity fixes the observed `(|drive_zero_start)`. Public vector truthiness
now lowers through explicit helper loops rather than native reduction syntax.

No VHDL compiler is installed, so the audit does not select or qualify native
VHDL vector-reduction syntax. t1543 durably characterizes the current scalar/
vector pipeline, six-case converter matrix, and public parser boundary. The
audit changed no behavior. Clean audit commit `16f6140c4` and activation commit
`2da0d42c0` led to the separate completed implementation.

The first implementation preservation gate then proved blanket vector
rejection would regress shipped AMBA/APB direct VHDL: existing supported paths
contain reductions over `HRESP`, `wait_ctr`, and `addr_q`. `.2` therefore uses
backend-owned `std_logic` fold helpers for declaration-proven vectors while
retaining fail-closed range/unresolved/compound handling. This does not select
native vector syntax or claim executable VHDL qualification.
