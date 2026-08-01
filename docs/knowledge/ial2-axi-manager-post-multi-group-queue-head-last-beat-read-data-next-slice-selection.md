---
id: ial2-axi-manager-post-multi-group-queue-head-last-beat-read-data-next-slice-selection
title: IAL2 selector chooses multi-group queue-head report-only raw-ARLEN capture
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.131 select?"
  - "what is the next slice after multi-group queue-head last-beat read-data?"
  - "should multi-group scalar queue-head read-data add raw ARLEN before runtime validation?"
  - "why did multi-group scalar runtime validation wait for a later owner?"
date: 2026-06-15
status: current
tags: [ial2, axi, manager, queue-head, read-data, same-id, burst-length, selector]
evidence: >-
  docs/AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_LAST_BEAT_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_READ_DATA_BEHAVIOR.md; ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_read_data.ppif; ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length.ppif; ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length_runtime_assertion.ppif;
  ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_read_data.ppif; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: >-
  env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_read_data.ppif && env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length.ppif && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.131|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.132|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.135|report-only raw|multi-group queue-head scalar last-beat read-data|runtime beat-count' docs/AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION.md docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md
  README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.131` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.132`, generated report-only raw-`ARLEN`
burst-length capture for multi-group queue-head scalar last-beat read-data.

The selector is documentation-only. It changes no parser, generator, PPIF
sample, support-accounting, test, generated artifact, or HDL behavior.

The selected `.132` boundary is generated read burst-last queue-head demux,
two or more depth-2 duplicate concrete read-ID groups, scalar
`capture_scope last-beat`, `completion-source response-demux`, `status-policy
last-beat`, `interleaving last-beat-by-rid`, `burst_length` metadata with
`source arlen`, signal width `8`, `encoding axlen-plus-one`, `capture
request`, and `validation report-only`, plus complete scalar
`data_output` / `status_output` bindings for every covered transaction.

Runtime beat-count/`RLAST` validation for the same multi-group scalar shape
was left to a later owner because it adds expected-beat storage, beat-count
storage, matched-read-beat count rules, and assertions for every covered
transaction. That later runtime-validation owner is now shipped by
`IAL2-FEATURE-COMPLETENESS-FRONTIER.135`.
