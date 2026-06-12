---
id: ial2-axi-manager-same-id-ordering-first-slice
title: AXI same-ID first slice ships generated auto-ID avoidance
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.35 ship?"
  - "is same-ID ordering implemented now?"
  - "what does same_id_ordering report?"
  - "does response_demux.residue still include same_id_ordering?"
  - "what comes after AXI same-ID avoidance?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, same-id, ordering, auto-id, assertions, report, task-tree]
evidence: docs/AXI_IAL2_MANAGER_SAME_ID_ORDERING_FIRST_SLICE.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; ppif/axi_manager_capacity_status_response_demux.ppif; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.35|same_id_ordering|auto_id_same_id_avoidance|avoid_same_id_concurrency|axi0_w0_w1_auto_id_unique_active_id|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.37|read response-demux' docs/AXI_IAL2_MANAGER_SAME_ID_ORDERING_FIRST_SLICE.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1437-axi-ial2-manager-capacity-status-generator.t t/1436-ial2-ppif-parser-cli.t docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.35` shipped the first bounded AXI
same-ID ordering implementation boundary for generated auto-ID families.

The shipped strategy is `avoid_same_id_concurrency`. FSMGen emits pairwise
runtime assertions proving active generated auto-ID transaction states do not
share the same selected ID, for example
`axi0_w0_w1_auto_id_unique_active_id`.

Reports now add a machine-readable `same_id_ordering` section with mode
`auto_id_same_id_avoidance`, covered family metadata, generated assertion
names, source anchors, and residue. For the response-demux sample,
`auto_id_lifecycle.residue` is empty and `response_demux.residue` is
`[read_response_demux, read_data_interleaving, bursts]`.

This is not full AXI same-ID ordering. Authored concrete-ID same-ID ordering,
per-ID issue-order queues/scoreboards, read `RID` response demux, read-data
interleaving/reassembly, bursts, queued/blocking policy, full-manager syntax,
and VHDL remain future exact-owner work. `.36` selected `.37`, read
response-demux readiness, as the next exact slice.
