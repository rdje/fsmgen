---
id: ial2-post-named-drive-priority-next-owner-selection
title: Direct-VHDL unary reduction correctness follows named-drive priority shipment
answers:
  - "what follows named-drive rule transaction priority shipment?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.831 select?"
  - "what owns the direct VHDL unary reduction token leak?"
  - "why is DIRECT-VHDL-REDUCTION-EXPRESSION-LOWERING selected next?"
  - "why does generated VHDL contain (|drive_zero_start)?"
  - "does successful direct VHDL generation prove valid VHDL?"
  - "is a VHDL compiler available for the reduction audit?"
date: 2026-07-30
status: current
tags: [ial2, selector, vhdl, backend, reduction, correctness, named-drive]
evidence: docs/IAL2_POST_NAMED_DRIVE_PRIORITY_NEXT_OWNER_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/tasks/DIRECT-VHDL-REDUCTION-EXPRESSION-LOWERING.md; docs/decisions/0023-vhdl-generation-success-is-not-reduction-expression-validation.md; perl/FSM/HDL/FlattenedDT/Backend/VHDL.pm; t/1420-vhdl-direct-backend-scaffold.t; t/1542-isf-rule-transaction-named-drive-priority-readiness.t
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.831|DIRECT-VHDL-REDUCTION-EXPRESSION-LOWERING\.1|\(\|drive_zero_start\)|_sv_expr_to_vhdl|ghdl|nvc|vcom' docs/IAL2_POST_NAMED_DRIVE_PRIORITY_NEXT_OWNER_SELECTION.md docs/tasks/DIRECT-VHDL-REDUCTION-EXPRESSION-LOWERING.md docs/decisions/0023-vhdl-generation-success-is-not-reduction-expression-validation.md perl/FSM/HDL/FlattenedDT/Backend/VHDL.pm
---

Parent selector `.831` selects proposed no-behavior audit
`DIRECT-VHDL-REDUCTION-EXPRESSION-LOWERING.1` after protocol-neutral
named-drive priority ships.

The direct VHDL path currently emits SystemVerilog unary-reduction residue,
including `drive_zero_en and (|drive_zero_start)`. `_sv_expr_to_vhdl`
translates spaced binary operators but neither translates nor rejects unary
reduction OR, AND, and XOR. The selected audit must distinguish scalar identity
from vector reduction semantics and choose the smallest correct translation or
fail-closed boundary without changing behavior.

No `ghdl`, `nvc`, or `vcom` executable is installed. That prevents an
authoritative executable-VHDL qualification claim, but does not block the
no-behavior audit or a later internal fail-closed repair. HIAL/VIAL, scale,
broader AHB/ISF work, simulator profiles, other tracked defects, other
protocols/backends, and decision `0020` remain separate.

Clean selector commit `5f904d2d2` activates only audit `.1`; activation is
continuity-only and leaves product behavior unchanged.

Completed audit `.1` selects proposed `.2` to lower declaration-proven scalar
and static-bit-select reductions by identity/complement. Implementation-time
preservation reconciles declared vectors to backend-owned folds while ranges,
invalid selects, unresolved/compound/malformed/residual forms reject. Public
source arity remains unchanged.

Clean audit commit `16f6140c4` activates only `.2` continuity state. The
foreign-token leak and all shipped behavior remain unchanged until the
implementation slice completes.

Completed `.2` now ships the reconciled scalar/static-bit/vector-fold contract,
token-free named-drive/AMBA/APB output, and unchanged public syntax. Proposed
parent selector `.832` owns the next roadmap choice after the clean behavior
commit.
