---
id: ial2-axi-manager-post-queue-head-multi-beat-next-slice-selection
title: IAL2 queue-head multi-beat selector chose multiple depth-2 group readiness
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.122 select?"
  - "what is the next slice after queue-head multi-beat read-data?"
  - "why are multiple queue-head groups next?"
  - "is queue-head read-data over multiple groups selected?"
date: 2026-06-15
status: current
tags: [ial2, axi, manager, queue-head, same-id, response-demux, task-tree]
evidence: docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_MULTI_BEAT_NEXT_SLICE_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.122|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.123|multiple independent read burst-last depth-2 concrete same-ID queue-head response-demux groups|read_multi_beat_same_id_queue_head_read_data|per_beat_output_bank|response_demux\\.residue: \\[\\]' docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_MULTI_BEAT_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.122` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.123`, readiness audit for multiple
independent read burst-last depth-2 concrete same-ID queue-head response-demux
groups.

The selector chose topology readiness because `.121` already clears local
`read_data` and `response_demux` residue for the bounded queue-head
multi-beat sample. The next risk is whether the compact one-hot queue-slot
representation, group-local transition rules, completion pulses, assertions,
reports, diagnostics, and lowerer behavior can scale from one duplicate
concrete read-ID group to multiple independent groups without changing the
payload contract.

`.123` was audit-only. It selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.124`, generated read burst-last
response-demux-only queue-head behavior for multiple duplicate concrete read-ID
groups, while preserving the existing family-wide admitted-request onehot
boundary. It explicitly defers read-data over multiple groups, deeper queues,
same-family mixed auto-ID plus concrete queue-head demux, write-family
multi-group behavior, packed burst-vector outputs, direct backend, and VHDL.
