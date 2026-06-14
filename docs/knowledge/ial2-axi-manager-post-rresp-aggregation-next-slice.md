---
id: ial2-axi-manager-post-rresp-aggregation-next-slice
title: Post-RRESP aggregation selector chose per-ID read-data interleaving readiness
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.80?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.80 select?"
  - "what comes after generated scalar RRESP aggregation?"
  - "where does FSMGEN verification-code generation fit?"
  - "should verification output be part of the synthesizable RTL lane?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, read-data, interleaving, queues, verification, task-tree]
evidence: docs/AXI_IAL2_MANAGER_POST_RRESP_AGGREGATION_NEXT_SLICE_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.80|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.81|per-ID read-data interleaving and queue readiness|verification-code generation|SV/UVM' docs/AXI_IAL2_MANAGER_POST_RRESP_AGGREGATION_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.80` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.81`, AXI per-ID read-data interleaving
and queue readiness, as the next exact audit after generated scalar `RRESP`
aggregation behavior.

The selection is based on the live public multi-beat schedule report:
`read_data.residue` and `auto_id_lifecycle.residue` are empty, while
`response_demux.residue` still contains `read_data_interleaving` and `bursts`,
and `same_id_ordering.residue` still contains `concrete_id_same_id_ordering`,
`per_id_issue_order_queues`, `read_data_interleaving`, and `bursts`.

Verification-code generation is a valid future FSMGEN target route, but `.80`
keeps it separate from the current synthesizable RTL/HDL feature-completeness
path. A later roadmap lane should own SV/UVM agents, monitors, scoreboards,
protocol checkers, coverage, and reusable verification IP so verification
targets can use non-synthesizable target-language constructs freely.
