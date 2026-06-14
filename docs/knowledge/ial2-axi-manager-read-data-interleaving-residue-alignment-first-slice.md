---
id: ial2-axi-manager-read-data-interleaving-residue-alignment-first-slice
title: AXI read-data interleaving residue is aligned for the covered generated subset
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.82?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.82 ship?"
  - "does response_demux still report read_data_interleaving residue for the public multi-beat sample?"
  - "does same_id_ordering still report read_data_interleaving residue for the public multi-beat sample?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.82?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, read-data, interleaving, residue, report, task-tree]
evidence: docs/AXI_IAL2_MANAGER_READ_DATA_INTERLEAVING_RESIDUE_ALIGNMENT_FIRST_SLICE.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.82|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.83|_read_data_covers_multi_beat_by_rid_interleaving|response_demux=\\[bursts\\]|same_id_ordering=\\[concrete_id_same_id_ordering,per_id_issue_order_queues,bursts\\]|READ_DATA_INTERLEAVING_RESIDUE_ALIGNMENT_FIRST_SLICE' docs/AXI_IAL2_MANAGER_READ_DATA_INTERLEAVING_RESIDUE_ALIGNMENT_FIRST_SLICE.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1436-ial2-ppif-parser-cli.t t/1437-axi-ial2-manager-capacity-status-generator.t docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.82` aligned report/static
`read_data_interleaving` residue for the covered generated auto-ID
multi-beat-by-RID subset.

The public multi-beat sample now reports `response_demux.residue: [bursts]`
and `same_id_ordering.residue: [concrete_id_same_id_ordering,
per_id_issue_order_queues, bursts]`; `read_data.residue` remains empty and
`auto_id_lifecycle.residue` remains empty.

Generated `.isf`, `.fsm`, and SystemVerilog behavior is unchanged. The next
active leaf is `IAL2-FEATURE-COMPLETENESS-FRONTIER.83`, which selects the
next AXI manager residue owner.
