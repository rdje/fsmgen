---
id: ial2-post-mixed-queue-multi-beat-next-slice-selection
title: Broader mixed issue-order queue cardinality readiness follows the bounded mixed queue multi-beat path
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.522 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.523?"
  - "what follows mixed issue-order queue multi-beat output banks?"
  - "why is broader mixed write BID queue readiness next?"
date: 2026-06-26
status: current
tags: [ial2, axi, manager, dynamic-id, static-id, issue-order-queue, cardinality, task-tree]
evidence: docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_NEXT_SLICE_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/knowledge/ial2-feature-completeness-priority.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.522|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.523|POST_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_NEXT_SLICE_SELECTION|one-dynamic plus two-concrete-static mixed dynamic/static write BID same-ID issue-order queue|broader mixed issue-order queue cardinality' docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/knowledge/ial2-post-mixed-queue-multi-beat-next-slice-selection.md docs/knowledge/ial2-feature-completeness-priority.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.522` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.523`, readiness audit for broader mixed
dynamic/static write `BID` same-ID `issue-order-queue` cardinality.

The selected audit is bounded to one dynamic write transaction plus two
concrete static write transactions. It follows `.520`, which shipped the
bounded one-dynamic plus one-static mixed queue read-data multi-beat path, and
`.521`, which synchronized public contract summaries with that behavior.

Write `BID` is the next audit because it widens static siblings without adding
read `RLAST`, read-data, raw-`ARLEN`, runtime-validation, multi-beat,
scoreboard, backend, verification-output, backend-language, external-converter,
or VHDL behavior.
