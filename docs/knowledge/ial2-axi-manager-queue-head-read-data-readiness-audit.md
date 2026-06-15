---
id: ial2-axi-manager-queue-head-read-data-readiness-audit
title: Queue-head read-data readiness selects direct single-beat behavior
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.112 decide?"
  - "what comes after the queue-head read-data readiness audit?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.113?"
  - "does queue-head read-data need a lowerer prerequisite?"
  - "why is removing the read_data queue-head guard not enough?"
date: 2026-06-15
status: current
tags: [ial2, axi, manager, read-data, same-id, queue-head, readiness, generated-behavior]
evidence: docs/AXI_IAL2_MANAGER_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_READ_SINGLE_BEAT_SAME_ID_QUEUE_BEHAVIOR_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_READ_DATA_BEHAVIOR_FIRST_SLICE.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.112|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.113|generated_queue_head_response_demux_completion_pulse|read_data cannot consume concrete same-ID queue-head|auto_transactions|generated_completion_signals' docs/AXI_IAL2_MANAGER_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1437-axi-ial2-manager-capacity-status-generator.t t/1436-ial2-ppif-parser-cli.t README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.112` found no new IAL1, IAL0, or
SystemVerilog prerequisite for queue-head read-data capture. The existing
read-data capture rules already use generated transaction completion pulses as
guards and ordinary held assignments for `RDATA`/`RRESP`.

The next leaf is `IAL2-FEATURE-COMPLETENESS-FRONTIER.113`: generated
single-beat read-data capture for the bounded read single-beat concrete
same-ID queue-head demux shape.

The implementation cannot just remove the current fail-closed guard. Existing
read-data normalization derives coverage from
`response_demux.read.auto_transactions`, while generated queue-head read demux
publishes generated completion signals and concrete queue transactions through
the queue-head metadata. `.113` must make read-data coverage source-aware and
report queue-head completion-pulse validity while preserving existing auto-ID
read-data behavior.
