---
id: ial2-axi-manager-post-read-single-beat-multi-group-queue-head-response-demux-next-slice-selection
title: IAL2 selects read-data over read single-beat multi-group queue-head readiness audit
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.144 select?"
  - "what comes after read single-beat multi-group queue-head response-demux?"
  - "is read-data over multiple read single-beat queue-head groups implemented?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.145?"
  - "why audit read-data over read single-beat multi-group queue-head groups first?"
date: 2026-06-16
status: current
tags: [ial2, axi, manager, queue-head, read-data, same-id, single-beat, task-tree]
evidence: docs/AXI_IAL2_MANAGER_POST_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_QUEUE_HEAD_READ_DATA_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Adapter/IAL2/PPIF.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_response_demux.ppif && env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_single_beat_same_id_queue_head_read_data.ppif && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.144|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.145|read-data over read single-beat multi-group|generated_read_single_beat_queue_head_demux|read single-beat multi-group queue-head response-demux' docs/AXI_IAL2_MANAGER_POST_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.144` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.145`, readiness audit for generated
read-data over read single-beat multi-group queue-head response-demux.

The selector did not change parser, generator, sample, support-accounting,
test, generated artifact, or HDL behavior. The current public boundary remains
response-demux-only for
`ppif/axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_response_demux.ppif`.

Live reports showed that `.143` generates two depth-2 read single-beat
queue-head groups and four generated completion pulses with no `read_data`;
the one-group single-beat queue-head read-data sample is generated; and
burst-last multi-group queue-head read-data is generated for the selected
scalar and multi-beat shapes. The support-detail residue still defers
read-data over multiple read single-beat queue-head groups.

`.145` must audit whether the local queue-head read-data coverage gate can be
safely widened for `generated_read_single_beat_queue_head_demux` from exactly
one depth-2 group to one-or-more depth-2 groups, while defining fixture,
support-accounting, check JSON, semantic JSON, HDL, report/residue,
diagnostic, preservation, documentation, and rollback boundaries before any
behavior change.
