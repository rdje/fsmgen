---
id: ial2-post-generalized-busy-count-next-owner-selection
title: Protocol-neutral named-drive output priority follows generalized AHB BUSY count shipment
answers:
  - "what follows generalized AHB requester BUSY counts 2 through 16?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.830 select?"
  - "does direct rule versus transaction output priority already work?"
  - "why can a transaction-invoked named drive still conflict with a rule output?"
  - "what owns named-drive output selector priority enforcement?"
  - "why are AHB requester BUSY counts above 16 not selected next?"
date: 2026-07-30
status: current
tags: [ial2, ahb, busy, selector, isf, priority, rule, transaction, drive]
evidence: docs/IAL2_POST_GENERALIZED_BUSY_COUNT_NEXT_OWNER_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/tasks/ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT.md; docs/IAL2_AHB_REQUESTER_MULTI_BUSY_INSERTION_READINESS_AUDIT.md; perl/FSM/Scheduler/ISF/LoweringIR.pm; t/1220-isf-arbitration-schedule-report.t
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.830|transaction-invoked named drive|_apply_rule_transaction_priority_resolution|isf_unproven_rule_drive_overlap|selector multi-value conflict' docs/IAL2_POST_GENERALIZED_BUSY_COUNT_NEXT_OWNER_SELECTION.md docs/tasks/ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT.md docs/IAL2_AHB_REQUESTER_MULTI_BUSY_INSERTION_READINESS_AUDIT.md perl/FSM/Scheduler/ISF/LoweringIR.pm t/1220-isf-arbitration-schedule-report.t
---

Parent selector `.830` selects proposed no-behavior audit
`ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT.1` after canonical decimal
AHB requester `busy-beats` values `2..16` ship at unchanged 332/373/56 split
28/28.

The old priority-gap shorthand is now precisely bounded. Direct transaction
assignments already participate in `_apply_rule_transaction_priority_resolution`:
t1220 proves a higher-priority rule masks a direct transaction assignment and
the schedule reports that suppression. The rejected AHB candidate instead had
a transaction invoke a named drive. That drive body has lowering owner kind
`drive`, falls outside the current rule/transaction assignment pass, is
reported as `isf_unproven_rule_drive_overlap`, and can leave different-value
selectors enabled until the generated multi-value assertion fails.

Audit `.1` must reproduce both the working direct-assignment control and the
failing named-drive case in a protocol-neutral fixture, trace activation and
provenance through the unified selector, and select either an exact masking
contract or the smallest fail-closed prerequisite. It may not weaken selector
assertions and makes no behavior change. Counts above 16, dynamic BUSY policy,
multiple insertion points, HIAL/VIAL, VHDL, scale, other protocols/backends,
and decision `0020` remain separate.

Clean selector commit `f67705356` activates only audit `.1`; activation is
continuity-only and leaves all product behavior unchanged.

Completed audit `.1` selects proposed no-behavior contract `.2` for
unique-caller target-local masking and ambiguous-caller fail-closed handling;
current behavior remains unchanged.

Clean audit commit `e715a34c7` activates only contract `.2` without changing
product behavior.
