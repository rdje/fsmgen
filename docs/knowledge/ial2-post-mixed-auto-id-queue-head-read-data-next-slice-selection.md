---
id: ial2-post-mixed-auto-id-queue-head-read-data-next-slice-selection
title: IAL2 .198 selects mixed report-only raw-ARLEN burst-length readiness
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.198 select?"
  - "what is the next IAL2 slice after mixed scalar read-data?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.199?"
  - "is mixed burst-length over auto-id queue-head shipped?"
  - "is mixed multi-beat read-data next after .197?"
date: 2026-06-21
status: current
tags: [ial2, axi, manager, auto-id, same-id, queue-head, read-data, burst-length, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_MIXED_AUTO_ID_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.198|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.199|POST_MIXED_AUTO_ID_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION|mixed report-only raw-ARLEN burst-length' docs/AXI_IAL2_MANAGER_POST_MIXED_AUTO_ID_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/book/src/11-extensions-and-embedding.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.198` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.199`, a readiness audit for generated
report-only raw-`ARLEN` burst-length capture over the same-family mixed
auto-ID lifecycle plus concrete same-ID queue-head read burst-last scalar
last-beat read-data shape.

The behavior is not shipped yet. `.199` is audit-only and must decide whether a
later implementation can directly reuse existing `burst-length` syntax and the
transaction-list driven raw-`ARLEN` storage/capture/report helpers after the
mixed last-beat coverage gate is widened.

Mixed runtime beat-count/`RLAST` validation, mixed multi-beat output banks,
single-beat burst-length, group-local enqueue widening, write-family
read-data, packed outputs, direct backend, verification-output generation,
VHDL, and backend-language variants remain separately owned.
