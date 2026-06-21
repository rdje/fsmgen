---
id: ial2-mixed-auto-id-queue-head-burst-length-behavior
title: IAL2 .200 ships mixed auto-ID queue-head report-only raw-ARLEN burst-length
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.200 ship?"
  - "is mixed auto-id queue-head report-only burst-length supported?"
  - "which PPIF sample covers mixed auto-id queue-head burst-length?"
  - "what was the mixed runtime validation boundary immediately after .200?"
  - "what is the next IAL2 slice after .200?"
date: 2026-06-21
status: current
tags: [ial2, axi, manager, auto-id, same-id, queue-head, burst-length, behavior]
evidence: docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md; ppif/axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; t/248-regression-corpus-accounting.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.200|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.202|MIXED_AUTO_ID_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR|MIXED_AUTO_ID_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR|read_burst_last_mixed_auto_id_same_id_queue_head_burst_length' docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/book/src/11-extensions-and-embedding.md MEMORY.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.200` ships support-accounted report-only
raw-`ARLEN` burst-length capture for
`ppif/axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length.ppif`.

The sample covers one read auto-ID transaction plus one depth-2 concrete
same-ID queue-head group, read `burst-last` response-demux, scalar last-beat
`RDATA`/`RRESP`, and per-transaction raw-`ARLEN` storage/capture for
`r0`, `r1`, and `r2`. Immediately after `.200`, runtime beat-count/`RLAST`
validation for the same mixed shape remained non-public and failed closed as
separately owned. `.202` later ships that runtime-validation sibling; see
`ial2-mixed-auto-id-queue-head-runtime-validation-behavior`.
