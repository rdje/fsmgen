---
id: ial2-post-dynamic-write-id-next-slice-selection
title: IAL2 post-dynamic-write selector chooses dynamic read ID readiness
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.224 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.225?"
  - "what follows generated dynamic write transaction ID matching?"
  - "why is dynamic read ID matching next?"
date: 2026-06-22
status: current
tags: [ial2, axi, dynamic-id, read-response-demux, readiness, task-tree]
evidence: docs/AXI_IAL2_MANAGER_POST_DYNAMIC_WRITE_ID_NEXT_SLICE_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.224|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.225|dynamic read transaction-ID|RID response matching|POST_DYNAMIC_WRITE_ID_NEXT_SLICE_SELECTION' docs/AXI_IAL2_MANAGER_POST_DYNAMIC_WRITE_ID_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.224` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.225`, a readiness audit for generated
dynamic read transaction-ID capture and `RID` response matching.

The selector does not change parser, generator, PPIF sample, support
accounting, generated artifact, test, or HDL behavior.

Dynamic read matching is next because `.223` shipped the first bounded dynamic
write behavior, while read matching still needs a readiness audit for response
scope, `RLAST`, read-data consumption, burst/runtime validation,
interleaving, assertions, diagnostics, and report vocabulary before any direct
behavior owner is selected.
