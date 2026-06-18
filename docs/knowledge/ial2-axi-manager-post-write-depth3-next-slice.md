---
id: ial2-axi-manager-post-write-depth3-next-slice
title: After write depth-3 queue-head response-demux, multiple or mixed depth-3 readiness is next
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.172 select?"
  - "what is the next IAL2 frontier after write depth-3 queue-head response-demux?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.173?"
  - "why are multiple or mixed depth-3 queue-head groups next?"
date: 2026-06-18
status: current
tags: [ial2, axi, manager, response-demux, queue-head, depth-3, readiness]
evidence: docs/AXI_IAL2_MANAGER_POST_WRITE_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_WRITE_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.172|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.173|POST_WRITE_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION|multiple or mixed depth-3|generated_same_id_queue_head_demux' docs/AXI_IAL2_MANAGER_POST_WRITE_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.172` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.173`, readiness audit for generated
multiple or mixed depth-3 concrete same-ID queue-head response-demux groups.

The selector chose that audit because the project now has generated one-group
depth-3 response-demux behavior for read single-beat, read burst-last, and
write families, and generated multi-group depth-2 response-demux behavior for
the same response-demux-only family shapes. Temporary write-family probes for
two depth-3 groups and mixed depth-3/depth-2 groups strict-check with no
diagnostics, report selected queue-head metadata, and remain
selected-not-generated only with `generated_same_id_queue_head_demux` residue.

`.173` is audit-only. It must decide whether the next behavior owner should
cover all response-demux-only multiple/mixed depth-3 families or a smaller
first family/scope. Read-data, burst-length, runtime-validation, multi-beat
payload, mixed auto-ID, group-local enqueue widening, packed outputs, direct
backend, verification-output generation, VHDL, and backend-language variants
remain deferred behind future exact owners.
