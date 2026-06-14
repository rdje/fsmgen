---
id: ial2-axi-manager-burst-residue-alignment-first-slice
title: AXI burst residue is aligned for the covered generated multi-beat output bank
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.85?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.85 ship?"
  - "does response_demux still report bursts residue for the public multi-beat sample?"
  - "does same_id_ordering still report bursts residue for the public multi-beat sample?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.85?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, bursts, read-data, output-bank, residue, report, task-tree]
evidence: docs/AXI_IAL2_MANAGER_BURST_RESIDUE_ALIGNMENT_FIRST_SLICE.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.85|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.86|_read_data_covers_bounded_multi_beat_burst_output|response_demux\\.residue: \\[\\]|same_id_ordering\\.residue|BURST_RESIDUE_ALIGNMENT_FIRST_SLICE' docs/AXI_IAL2_MANAGER_BURST_RESIDUE_ALIGNMENT_FIRST_SLICE.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1436-ial2-ppif-parser-cli.t t/1437-axi-ial2-manager-capacity-status-generator.t docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.85` aligned report/static `bursts`
residue for the covered generated auto-ID multi-beat output-bank subset.

The public multi-beat sample now reports `response_demux.residue: []` and
`same_id_ordering.residue: [concrete_id_same_id_ordering,
per_id_issue_order_queues]`; `read_data.residue` remains empty.

Generated `.isf`, `.fsm`, and SystemVerilog behavior is unchanged. The
predicate requires generated read same-ID avoidance, generated burst-last read
response demux, ARLEN-derived expected beats, runtime beat-count/RLAST
validation, matched-read-beat counting, per-transaction output banks, full
configured data/status lane lists, valid masks, length outputs, and generated
multi-beat output-bank behavior.

The follow-up leaf was `IAL2-FEATURE-COMPLETENESS-FRONTIER.86`, which selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.87`, AXI concrete-ID same-ID ordering
readiness.
