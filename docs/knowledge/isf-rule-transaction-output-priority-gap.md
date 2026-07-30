---
id: isf-rule-transaction-output-priority-gap
title: Historical named-drive rule/transaction priority gap before implementation .3
answers:
  - "does ISF priority resolve a rule and transaction driving different output values?"
  - "does direct rule versus transaction assignment priority already work?"
  - "does transaction priority propagate through a named drive?"
  - "why did the generated HTRANS selector report a multi-value conflict?"
  - "what owns rule versus transaction output priority enforcement?"
date: 2026-07-30
status: superseded
tags: [isf, scheduler, priority, rule, transaction, drive, output, selector, assertion]
evidence: docs/IAL2_AHB_REQUESTER_MULTI_BUSY_INSERTION_READINESS_AUDIT.md; docs/IAL2_POST_GENERALIZED_BUSY_COUNT_NEXT_OWNER_SELECTION.md; docs/tasks/ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT.md; perl/FSM/Scheduler/ISF/LoweringIR.pm; t/1220-isf-arbitration-schedule-report.t
reverify: rg -n 'selector multi-value conflict|_apply_rule_transaction_priority_resolution|isf_unproven_rule_drive_overlap|transaction-invoked named drive|priority_resolutions records rule-over-transaction' docs/IAL2_AHB_REQUESTER_MULTI_BUSY_INSERTION_READINESS_AUDIT.md docs/IAL2_POST_GENERALIZED_BUSY_COUNT_NEXT_OWNER_SELECTION.md docs/tasks/ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT.md perl/FSM/Scheduler/ISF/LoweringIR.pm t/1220-isf-arbitration-schedule-report.t
---

A disposable IAL1 candidate declared a concurrent BUSY-hold rule higher
priority than its requester transaction. The schedule accepted the declaration
and storage-write conflicts were resolved, but generated `HTRANS` logic still
enabled the rule's BUSY selector and the transaction-invoked named drive's SEQ
selector in the same cycle. With generated assertions enabled, runtime failed
on `selector multi-value conflict: HTRANS`.

Direct transaction output assignments are not the gap:
`_apply_rule_transaction_priority_resolution` already suppresses them, and
t1220 proves the schedule reports a higher-priority rule masking a direct
transaction assignment. Named-drive bodies carry owner kind `drive`, remain
outside that pass, and conflict analysis reports rule/drive overlap as
`isf_unproven_rule_drive_overlap`.

Parent selector `.830` now selects proposed audit `.1` under inactive tree
`ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT`. The audit owns the
protocol-neutral direct-assignment control, named-drive reproducer,
provenance/activation trace, and later choice between exact selector masking
and a fail-closed prerequisite. It may not weaken generated selector
assertions or change behavior.

Clean selector commit `f67705356` activates audit `.1` without changing the
working direct-assignment path or unresolved named-drive behavior.

Completed audit `.1` adds tracked t1542 proof and selects proposed contract
`.2`: mask only conflicting named-drive targets for exactly one local
transaction caller, and fail closed when caller ownership is ambiguous.
Current lowering remains unchanged until implementation.

Clean audit commit `e715a34c7` activates only no-behavior contract `.2`.

Completed contract `.2` selects `.3`; it preserves drive provenance, uses
private unique-caller metadata for priority analysis, and fails prioritized
ambiguous ownership before HDL. Clean contract commit `b44afcc51` activates
`.3` continuity-only. The separately found direct-VHDL reduction token leak
does not change current lowering behavior.

This gap is closed by implementation `.3`. Current behavior is canonical in
`isf-rule-transaction-named-drive-priority-behavior`; this card remains only as
the dated root-cause record.
