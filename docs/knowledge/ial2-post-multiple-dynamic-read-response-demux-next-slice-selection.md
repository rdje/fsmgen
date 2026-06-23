---
id: ial2-post-multiple-dynamic-read-response-demux-next-slice-selection
title: Post multiple dynamic read demux selector picks burst-last audit
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.252 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.253?"
  - "what is the next IAL2 slice after multiple dynamic read response-demux?"
  - "why audit multiple dynamic read burst-last/RLAST next?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, read-response-demux, selection]
evidence: docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.252|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.253|POST_MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_NEXT_SLICE_SELECTION|multiple dynamic read burst-last|bounded multiple dynamic read single-beat' docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.252` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.253`, readiness audit for multiple dynamic
read burst-last/`RLAST` response-demux after `.251` shipped bounded multiple
dynamic read single-beat response-demux.

The selector chooses burst-last readiness next because read-data,
burst-length/runtime validation, and multi-beat output-bank widening over
multiple dynamic reads all depend on the response-demux lifetime: raw
`RID == captured_id` beat matching must remain separate from final
`RID && RLAST` completion.

`.253` must decide whether the next owner is direct generated behavior,
contract selection, helper cleanup, report/static cleanup, or a narrower
prerequisite. It must not change parser, generator, PPIF samples,
support-accounting catalog, validation behavior, generated artifacts, tests,
schedule/check/semantic JSON, or HDL behavior unless it explicitly selects a
later implementation owner.
