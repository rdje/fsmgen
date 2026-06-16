---
id: specforge-transaction-phase-membership-response
title: SPECFORGE transaction phase membership stays ISF metadata, not fabricated behavior
answers:
  - "how should SPECFORGE lower transaction phase membership without values?"
  - "should SPECFORGE use .val instead of .isf?"
  - "does FSMGen need code changes for SPECFORGE phase membership?"
  - "should bare drive be a participation marker?"
  - "what is .val for in verification generation?"
  - "where is the SPECFORGE phase membership response?"
date: 2026-06-16
status: current
tags: [specforge, isf, verification, val, phase-metadata]
evidence: docs/SPECFORGE_FEEDBACK_RESPONSE.md; docs/tasks/ISF-SPECFORGE-PHASE-MEMBERSHIP-RESPONSE.md; docs/tasks/IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.md
reverify: rg -n 'Transaction Phase Membership Without Fabricated Values Or Order|ISF-SPECFORGE-PHASE-MEMBERSHIP-RESPONSE|bare `drive`|phase-group metadata|\\.val|Verification Abstraction Layer|not a replacement for `\\.isf`' docs/SPECFORGE_FEEDBACK_RESPONSE.md docs/tasks/ISF-SPECFORGE-PHASE-MEMBERSHIP-RESPONSE.md docs/tasks/IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.md README.md MEMORY.md
---

FSMGen's tracked response to SPECFORGE's `2026-06-16` transaction
phase-membership/value/order request is in
`docs/SPECFORGE_FEEDBACK_RESPONSE.md`, section
`2026-06-16: Transaction Phase Membership Without Fabricated Values Or Order`.

No runtime FSMGen code change was required to answer the question. The current
guidance is:

- do not treat bare `(drive S)` as an output-participation marker;
- do not fabricate output drive values or transaction-body order;
- use transaction bodies only for grounded implementation behavior;
- keep ungrounded phase membership in SPECFORGE IntentIR metadata/residuals
  until FSMGen selects checked transaction phase-group metadata;
- keep `.isf` as SPECFORGE's synthesizable target;
- treat `.val`, if ever selected, as a future verification artifact/layer
  derived from `.isf` or schedule reports, not as a replacement for `.isf`.

Any future checked transaction phase-group metadata implementation must have
its own task-tree owner before parser/report/code changes.
