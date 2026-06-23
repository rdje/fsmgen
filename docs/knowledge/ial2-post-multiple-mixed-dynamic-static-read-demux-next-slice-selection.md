---
id: ial2-post-multiple-mixed-dynamic-static-read-demux-next-slice-selection
title: Post multiple mixed dynamic/static read demux selector picks burst-last audit
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.300 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.301?"
  - "what is the next IAL2 slice after multiple mixed dynamic/static read response-demux?"
  - "why audit multiple mixed dynamic/static read burst-last next?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, read-response-demux, selection]
evidence: docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DEMUX_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.300|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.301|POST_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DEMUX_NEXT_SLICE_SELECTION|multiple mixed dynamic/static read burst-last|bounded multiple mixed dynamic/static read single-beat' docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DEMUX_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.300` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.301`, readiness audit for multiple mixed
dynamic/static read burst-last `RID && RLAST` response-demux after `.299`
shipped bounded multiple mixed dynamic/static read single-beat `RID`
response-demux.

The selector chooses burst-last readiness next because read-data,
burst-length/runtime validation, and multi-beat output-bank widening over the
multi-static mixed read shape depend on final-beat completion semantics. The
audit should verify whether the `.299` list-shaped mixed read ownership path
can reuse the `.280` burst-last final-completion pattern while preserving the
`.276` one-dynamic plus one-static report contract.

`.301` must decide whether the next owner is public contract selection,
direct generated behavior, helper/report cleanup, or a narrower prerequisite.
It must not change parser, generator, PPIF samples, support-accounting catalog,
validation behavior, generated artifacts, tests, schedule/check/semantic JSON,
or HDL behavior unless it explicitly selects a later implementation owner.
