---
id: ial2-feature-completeness-next-slice
title: IAL2 feature completeness next slice is same-ID queue expansion audit
answers:
  - "what is the next IAL2 feature completeness slice?"
  - "what is the next IAL2 PNT task?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.107?"
  - "what is the next AXI manager slice?"
  - "what is the next AXI manager task after same-ID queue behavior implementation?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, same-id, concrete-id, ordering, feature-completeness, task-tree]
evidence: docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_FIRST_SLICE_SELECTION.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md; docs/knowledge/ial2-common-vs-profile-factoring.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.106|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.107|generated_read_burst_last_queue_head_demux|next same-ID queue behavior expansion|common semantic core' docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_FIRST_SLICE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md docs/knowledge/ial2-common-vs-profile-factoring.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.106` shipped the first generated
same-ID queue behavior boundary for the public read burst-last depth-2 sample.

The next active leaf is `IAL2-FEATURE-COMPLETENESS-FRONTIER.107`. It audits
and selects the next AXI same-ID queue behavior expansion before any broader
behavior change.

The already-covered public sample now reports generated response demux,
generated same-ID ordering, `accepted_same_id_reuse: true`, and
`generated_queue_behavior: true` only for the bounded read burst-last
two-transaction depth-2 shape. Write queue-head behavior, read `single-beat`,
deeper or multiple groups, read-data consumption, direct backend, and VHDL
remain deferred.

The IAL2 factoring stance remains that common constructs should be promoted
only after compatible reuse is proven across multiple profiles.
