---
id: isf-rule-transaction-output-priority-gap
title: Transaction-level priority does not yet propagate through a conflicting named-drive output selector
answers:
  - "does ISF priority resolve a rule and transaction driving different output values?"
  - "does direct rule versus transaction assignment priority already work?"
  - "does transaction priority propagate through a named drive?"
  - "why did the generated HTRANS selector report a multi-value conflict?"
  - "what owns rule versus transaction output priority enforcement?"
date: 2026-07-30
status: current
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
