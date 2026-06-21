---
id: ial2-post-multiple-mixed-depth3-multi-beat-next-slice-selection
title: IAL2 post multi-beat output-bank selector chose mixed auto-ID queue-head readiness
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.192 select?"
  - "what is the next IAL2 frontier after multiple/mixed depth-3 multi-beat output banks?"
  - "why is mixed auto-ID plus concrete queue-head response-demux next?"
  - "is same-family mixed auto-ID plus concrete queue-head demux supported?"
date: 2026-06-21
status: current
tags: [ial2, axi, manager, auto-id, same-id, queue-head, response-demux, task-tree]
evidence: docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_MULTI_BEAT_NEXT_SLICE_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.192|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.193|same-family mixed auto-ID|concrete same-ID queue-head|POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_MULTI_BEAT_NEXT_SLICE_SELECTION' docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_MULTI_BEAT_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.192` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.193`, readiness audit for same-family
mixed auto-ID lifecycle plus concrete same-ID queue-head response-demux.

The current code intentionally fail-closes this same-family combination before
behavior generation. Adjacent pieces are shipped independently: bounded
auto-ID response-demux exists, and concrete same-ID queue-head response-demux
exists across selected read single-beat, read burst-last, write, depth-3,
multiple, and mixed depth-3/depth-2 shapes. The remaining question is how to
own completion validity, response-event fanout, report/residue shape, and
support accounting when both appear in one response family.

`.193` is audit-only. It must not change parser, generator, PPIF samples,
support-accounting catalog, validation, generated artifacts, tests, or HDL
behavior.
