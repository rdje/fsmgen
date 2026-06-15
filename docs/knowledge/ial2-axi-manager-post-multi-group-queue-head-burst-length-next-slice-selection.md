---
id: ial2-axi-manager-post-multi-group-queue-head-burst-length-next-slice-selection
title: IAL2 multi-group queue-head burst-length selector chose runtime-validation readiness
answers:
  - "what comes after multi-group queue-head report-only ARLEN capture?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.133 select?"
  - "is multi-group scalar runtime validation selected?"
  - "why is runtime-validation multi-group scalar an audit first?"
date: 2026-06-15
status: current
tags: [ial2, axi, manager, queue-head, read-data, same-id, burst-length, runtime-validation, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_BURST_LENGTH_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.133|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.134|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.135|runtime-validation multi-group queue-head scalar|generated_beat_count_validation|read_multi_group_last_beat_same_id_queue_head_burst_length|read_multi_group_last_beat_same_id_queue_head_burst_length_runtime_assertion|POST_MULTI_GROUP_QUEUE_HEAD_BURST_LENGTH_NEXT_SLICE_SELECTION' docs/AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_BURST_LENGTH_NEXT_SLICE_SELECTION.md docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.133` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.134`, readiness audit for generated
runtime-validation multi-group queue-head scalar last-beat read-data.

The selector follows `.132`, which shipped report-only raw-`ARLEN` capture for
`ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_burst_length.ppif`
and left `generated_beat_count_validation` as read-data residue.

The selector is audit-first because the next behavior would combine scalar
final outputs with expected-beat storage, matched-beat counters, and
beat-count/`RLAST` assertions across multiple queue groups. Existing evidence
is split across `.119` one-group scalar runtime validation and `.127`
multi-group multi-beat runtime validation, so `.134` must prove the scalar
multi-group composition boundary before implementation. `.134` later selected
direct implementation, and `.135` shipped the runtime-validation sibling.
