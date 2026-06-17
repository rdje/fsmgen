---
id: ial2-axi-manager-read-single-beat-multi-group-queue-head-read-data-behavior
title: IAL2 ships generated read single-beat multi-group queue-head read-data behavior
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.146 ship?"
  - "does FSMGen support read-data over read single-beat multi-group queue-head demux?"
  - "what PPIF sample covers read single-beat multi-group queue-head read-data?"
  - "what is the completion validity for read single-beat multi-group queue-head read-data?"
  - "is read-data over multiple read single-beat queue-head groups still deferred?"
date: 2026-06-16
status: current
tags: [ial2, axi, manager, queue-head, read-data, same-id, single-beat, behavior]
evidence: docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_READ_DATA_BEHAVIOR.md; ppif/axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_read_data.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; docs/REGRESSION_CORPUS.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/book/src/11-extensions-and-embedding.md
reverify: env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_read_data.ppif && env -u PERL5LIB ./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_read_data.ppif && env -u PERL5LIB ./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_read_data.ppif && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.146|axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_read_data|generated_queue_head_response_demux_completion_pulse|multiple independent read single-beat response-demux-only or scalar read-data queue groups' docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_READ_DATA_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/book/src/11-extensions-and-embedding.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.146` shipped generated read-data over
read single-beat multi-group queue-head response-demux.

The public sample is
`ppif/axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_read_data.ppif`.
It has two generated read single-beat queue-head groups: `r0`/`r1` share
concrete `RID` `3`, and `r2`/`r3` share concrete `RID` `5`. Each group stays
depth `2`.

The generated read-data report uses
`completion_validity: generated_queue_head_response_demux_completion_pulse`,
declares generated `axi0_rdata` and `axi0_rresp` inputs, and emits scalar
`RDATA`/`RRESP` capture rules for `r0` through `r3` guarded by the generated
queue-head completion pulses.

Strict check JSON and semantic JSON support-account the sample as
`intent.ppif_axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_read_data`.
Read-data over multiple read single-beat queue-head groups is no longer an
unsupported residue for this bounded depth-2 shape. A separate `.153` sibling
ships one selected depth-3 single-beat read-data group; additional queue-depth
widening beyond that shape, same-family mixed auto-ID, group-local enqueue
widening, packed outputs, direct backend, and VHDL remain deferred.
