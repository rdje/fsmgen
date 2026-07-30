---
id: isf-rule-transaction-named-drive-priority-contract-selection
title: Named-drive priority is target-local for one local transaction caller
answers:
  - "what named-drive priority contract did ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT.2 select?"
  - "how will rule transaction priority propagate through a named drive?"
  - "what happens when a named drive has multiple transaction callers?"
  - "what diagnostic handles ambiguous named-drive priority ownership?"
  - "does named-drive priority suppress the whole drive?"
  - "how are SystemVerilog Verilog and VHDL qualified for named-drive priority?"
date: 2026-07-30
status: current
tags: [isf, rule, transaction, named-drive, priority, contract, selector, backend]
evidence: docs/ISF_RULE_TRANSACTION_NAMED_DRIVE_PRIORITY_CONTRACT_SELECTION.md; docs/ISF_RULE_TRANSACTION_NAMED_DRIVE_PRIORITY_READINESS_AUDIT.md; docs/tasks/ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT.md; t/1542-isf-rule-transaction-named-drive-priority-readiness.t; perl/FSM/Scheduler/ISF/LoweringIR.pm
reverify: rg -n 'local_transaction_callers|generated_call_sources|isf_ambiguous_rule_transaction_drive_priority|invoking_transactions|priority_suppressed_by' docs/ISF_RULE_TRANSACTION_NAMED_DRIVE_PRIORITY_CONTRACT_SELECTION.md docs/tasks/ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT.md perl/FSM/Scheduler/ISF/LoweringIR.pm t/1542-isf-rule-transaction-named-drive-priority-readiness.t
---

Contract `.2` selects backend-neutral, assignment-local priority propagation
for a named drive with exactly one distinct local transaction caller and no
generated activation source. Drive provenance remains `owner_kind=drive`,
while private sorted `invoking_transactions` metadata lets priority analysis
use the single logical transaction actor.

A higher rule masks only the conflicting drive-body assignment under the
inverse rule condition. A higher transaction masks only the conflicting rule
under the inverse drive-body activation. The drive request, transaction,
parameters, completion, and non-conflicting drive outputs continue.

Different-value unique-caller overlaps without priority fail through
`isf_conflicting_rule_transaction_writes`. Prioritized shared/generated/mixed
ownership fails before HDL through
`isf_ambiguous_rule_transaction_drive_priority` with sorted caller/source
evidence. Same-value fan-in and the existing direct assignment path remain.

SystemVerilog plus Verilog receive executable structural/runtime qualification.
VHDL is explicitly unqualified for this expression family because current
direct output leaks unary reduction syntax; decision `0023` and proposed
`DIRECT-VHDL-REDUCTION-EXPRESSION-LOWERING` own that separate repair.

Clean contract commit `b44afcc51` activates implementation `.3` continuity-
only. Implementation `.3` now ships this unchanged contract; current behavior
is canonical in `isf-rule-transaction-named-drive-priority-behavior`.
