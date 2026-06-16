---
id: ial2-axi-manager-read-single-beat-multi-group-queue-head-read-data-readiness-audit
title: IAL2 selects generated read single-beat multi-group queue-head read-data behavior
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.145 decide?"
  - "what comes after the read-data over read single-beat multi-group queue-head audit?"
  - "can read-data over read single-beat multi-group queue-head demux be implemented directly?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.146?"
  - "what currently blocks read-data over multiple read single-beat queue-head groups?"
date: 2026-06-16
status: current
tags: [ial2, axi, manager, queue-head, read-data, same-id, single-beat, readiness]
evidence: docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_QUEUE_HEAD_READ_DATA_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Adapter/IAL2/PPIF.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_response_demux.ppif && env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_single_beat_same_id_queue_head_read_data.ppif && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.145|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.146|queue-head coverage requires exactly one depth-2|generated_queue_head_response_demux_completion_pulse|generated_read_single_beat_queue_head_demux' docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.145` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.146`, direct implementation of generated
read-data over read single-beat multi-group queue-head response-demux.

The audit made no parser, generator, PPIF sample, support-accounting, test,
generated artifact, or HDL behavior change. It found no new PPIF syntax, IAL1,
IAL0/SystemVerilog, direct-backend, or VHDL prerequisite before the bounded
behavior slice.

The current blocker is the exact-one-group gate in
`_read_data_response_demux_transaction_coverage` for
`generated_read_single_beat_queue_head_demux`. A temporary `/tmp` probe derived
from the `.143` public sample plus scalar single-beat read-data bindings for
`r0` through `r3` failed closed at the expected diagnostic requiring exactly
one depth-2 concrete same-ID read queue group.

`.146` should widen only that single-beat generated queue-head read-data
coverage boundary from exactly one depth-2 group to one-or-more depth-2 groups,
add the public support-accounted PPIF sample and tests, and keep deeper queues,
same-family mixed auto-ID, group-local enqueue widening, packed outputs, direct
backend, and VHDL deferred.
