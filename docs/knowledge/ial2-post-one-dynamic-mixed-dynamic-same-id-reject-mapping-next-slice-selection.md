---
id: ial2-post-one-dynamic-mixed-dynamic-same-id-reject-mapping-next-slice-selection
title: Post one-dynamic mixed dynamic same-ID reject selector chooses dynamic issue-order queue audit
answers:
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.447 select?"
  - "what comes after one-dynamic mixed dynamic same-ID reject mapping?"
  - "why audit dynamic issue-order queue policy before scoreboard?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.448?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, selector, issue-order-queue]
evidence: docs/AXI_IAL2_MANAGER_POST_ONE_DYNAMIC_MIXED_DYNAMIC_SAME_ID_REJECT_MAPPING_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_ONE_DYNAMIC_MIXED_DYNAMIC_SAME_ID_REJECT_MAPPING_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_POLICY_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_POLICY_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_READINESS_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.447|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.448|POST_ONE_DYNAMIC_MIXED_DYNAMIC_SAME_ID_REJECT_MAPPING_NEXT_SLICE_SELECTION|dynamic-id-reuse issue-order-queue|dynamic same-ID issue-order queue policy contract' docs/AXI_IAL2_MANAGER_POST_ONE_DYNAMIC_MIXED_DYNAMIC_SAME_ID_REJECT_MAPPING_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.447` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.448`, readiness audit for the public
dynamic same-ID `issue-order-queue` policy contract after the bounded
`dynamic-id-reuse reject` mappings shipped.

The selector changes no behavior. It chooses issue-order-queue contract
readiness because `.438`, `.442`, and `.446` cover generated reject mapping
while still reporting `accepted_same_id_reuse: false`,
`generated_queue_behavior: false`, and `generated_scoreboard_behavior:
false`.

Dynamic issue-order queues come before scoreboard because concrete same-ID
queue-head work already provides the closest bounded precedent. Dynamic
scoreboard behavior remains a separate later policy/readiness owner with a
different completion-tracking promise.
