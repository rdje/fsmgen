---
id: isf-rule-transaction-output-priority-gap
title: Declared rule-over-transaction priority does not mask a conflicting output drive selector
answers:
  - "does ISF priority resolve a rule and transaction driving different output values?"
  - "why did the generated HTRANS selector report a multi-value conflict?"
  - "what owns rule versus transaction output priority enforcement?"
date: 2026-07-24
status: current
tags: [isf, scheduler, priority, rule, transaction, drive, output, selector, assertion]
evidence: docs/IAL2_AHB_REQUESTER_MULTI_BUSY_INSERTION_READINESS_AUDIT.md; docs/tasks/ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT.md
reverify: rg -n 'rule.versus.transaction output-priority|selector multi-value conflict|ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT' docs/IAL2_AHB_REQUESTER_MULTI_BUSY_INSERTION_READINESS_AUDIT.md docs/tasks/ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT.md
---

A disposable IAL1 candidate declared a concurrent BUSY-hold rule higher
priority than its requester transaction. The schedule accepted the declaration
and storage-write conflicts were resolved, but generated `HTRANS` logic still
enabled the rule's BUSY selector and the transaction drive's SEQ selector in
the same cycle. With generated assertions enabled, runtime failed on
`selector multi-value conflict: HTRANS`.

The AHB repair avoids this mechanism, so the finding is nonblocking there.
Proposed inactive tree `ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT` owns
the protocol-neutral reproducer and any future scheduler/selector repair.
