---
id: ial2-feature-completeness-next-slice
title: IAL2 feature completeness next slice is same-ID reject policy metadata
answers:
  - "what is the next IAL2 feature completeness slice?"
  - "what is the next IAL2 PNT task?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.92?"
  - "what is the next AXI manager slice?"
  - "what is the next AXI manager task after concrete-ID same-ID validation?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, same-id, concrete-id, ordering, feature-completeness, task-tree]
evidence: docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/AXI_IAL2_MANAGER_SAME_ID_REUSE_POLICY_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_PER_ID_QUEUE_READINESS_AUDIT.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md; docs/knowledge/ial2-common-vs-profile-factoring.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.91|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.92|SAME_ID_REUSE_POLICY_CONTRACT_SELECTION|same-id-ordering|common semantic core' docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/AXI_IAL2_MANAGER_SAME_ID_REUSE_POLICY_CONTRACT_SELECTION.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md docs/knowledge/ial2-common-vs-profile-factoring.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.91` selected the public AXI same-ID reuse
policy contract before per-ID issue-order queues.

The next active leaf is `IAL2-FEATURE-COMPLETENESS-FRONTIER.92`. It implements
parser/report metadata and static validation for explicit
`same-id-ordering ... concrete-id-reuse reject` policy before generated per-ID
queue behavior.

The IAL2 factoring stance remains that common constructs should be promoted
only after compatible reuse is proven across multiple profiles.
