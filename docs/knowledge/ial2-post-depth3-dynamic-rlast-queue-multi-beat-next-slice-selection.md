---
id: ial2-post-depth3-dynamic-rlast-queue-multi-beat-next-slice-selection
title: Post depth-3 dynamic RLAST queue multi-beat selector chooses mixed queue readiness
answers:
  - "what comes after depth-3 dynamic RLAST queue multi-beat output banks?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.501 select?"
  - "is sv2v selected after depth-3 dynamic RLAST queue multi-beat?"
  - "why select mixed dynamic/static write BID issue-order queue readiness?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, static-id, mixed-dynamic-static, same-id-ordering, issue-order-queue, write-bid, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.501|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.502|POST_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_NEXT_SLICE_SELECTION|mixed dynamic/static write.*same-ID.*issue-order-queue|sv2v' docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`.501` selects `.502`, readiness audit for generated mixed dynamic/static
write `BID` same-ID `issue-order-queue` behavior with exactly one dynamic
write transaction and one concrete static write transaction.

The selector chooses this audit because `.500` closes the all-dynamic
depth-3 dynamic queue/read-data ladder, while mixed dynamic/static response
demux and all-dynamic issue-order queues are both shipped FSMGen-owned
substrates. A one-dynamic plus one-concrete-static write `BID` queue is the
smallest mixed queue shape: it avoids `RLAST`, read-data banking, raw
`ARLEN`, runtime beat-count validation, multi-beat output banks,
multi-static or two-dynamic-plus-static cardinalities, scoreboards, backend
variants, and VHDL.

FSMGen-owned generation/lowering remains the default. `sv2v` is not selected
as a dependency; it remains an optional future audit candidate only.
