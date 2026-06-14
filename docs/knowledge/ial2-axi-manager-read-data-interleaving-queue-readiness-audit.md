---
id: ial2-axi-manager-read-data-interleaving-queue-readiness-audit
title: AXI read-data interleaving audit selects residue alignment
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.81?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.81 select?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.81?"
  - "does the generated auto-ID multi-beat sample already cover by-RID output banks?"
  - "should the next AXI manager slice implement per-ID queues?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, read-data, interleaving, queues, residue, task-tree]
evidence: docs/AXI_IAL2_MANAGER_READ_DATA_INTERLEAVING_QUEUE_READINESS_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.81|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.82|READ_DATA_INTERLEAVING_QUEUE_READINESS_AUDIT|multi_beat_by_rid|matched.*RID|read_data_interleaving|per_id_issue_order_queues' docs/AXI_IAL2_MANAGER_READ_DATA_INTERLEAVING_QUEUE_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.81` audited AXI per-ID read-data
interleaving and queue readiness after generated scalar `RRESP` aggregation.

The covered generated auto-ID multi-beat sample already has bounded
`multi_beat_by_rid` output-bank behavior: generated same-ID avoidance prevents
same-family auto-ID collisions, read response demux matches accepted read
beats by `RID`, and each read transaction owns independent beat-count,
output-bank, valid-mask, length, and scalar aggregate status state.

The next slice is `IAL2-FEATURE-COMPLETENESS-FRONTIER.82`, report/static
residue alignment for that covered subset. It should not implement per-ID
queues; concrete-ID same-ID ordering, per-ID issue-order queues, broader
bursts, queued/blocking policy, profile aliases, full-manager behavior,
verification-code generation, direct backend lowering, and VHDL remain
deferred.
