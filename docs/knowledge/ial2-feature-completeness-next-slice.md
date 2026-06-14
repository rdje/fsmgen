---
id: ial2-feature-completeness-next-slice
title: IAL2 feature completeness next slice is AXI burst residue alignment
answers:
  - "what is the next IAL2 feature completeness slice?"
  - "what is the next IAL2 PNT task?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.85?"
  - "what is the next AXI manager slice?"
  - "what is the next AXI manager burst residue task?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, bursts, read-data, feature-completeness, task-tree, residue]
evidence: docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/AXI_IAL2_MANAGER_BURST_PAYLOAD_OUTPUT_READINESS_AUDIT.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.84|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.85|BURST_PAYLOAD_OUTPUT_READINESS_AUDIT|bursts residue alignment|response_demux\\.residue: \\[bursts\\]|same_id_ordering\\.residue' docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/AXI_IAL2_MANAGER_BURST_PAYLOAD_OUTPUT_READINESS_AUDIT.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.84` selected the next owner after
auditing AXI burst payload/output readiness for the covered generated auto-ID
multi-beat output-bank subset.

The next active leaf is `IAL2-FEATURE-COMPLETENESS-FRONTIER.85`. It aligns
AXI `bursts` residue after the public multi-beat sample now reports
`read_data.residue: []`, `response_demux.residue: [bursts]`, and
`same_id_ordering.residue: [concrete_id_same_id_ordering,
per_id_issue_order_queues, bursts]`.

`.85` should remove broad `bursts` residue only for the covered generated
auto-ID multi-beat output-bank subset, with generated behavior unchanged, and
keep packed/full burst assembly as deferred future work.
