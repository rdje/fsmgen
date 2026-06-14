---
id: ial2-axi-manager-burst-read-data-beat-count-contract-selection
title: AXI burst read-data beat-count contract selects ARLEN plus max-beats
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.62 select?"
  - "what burst-length syntax was selected?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.62?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.63?"
  - "does beat-count selection generate reassembly behavior?"
date: 2026-06-13
status: current
tags: [ial2, axi, manager, read-data, burst-length, arlen, beat-count, max-beats, selector, task-tree]
evidence: docs/AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_METADATA_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_POST_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.63|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.64|burst-length|source arlen|axlen-plus-one|max-beats|report-only' docs/AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_CONTRACT_SELECTION.md docs/AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_METADATA_FIRST_SLICE.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.62` selected an additive public
`burst-length` clause under last-beat `read-data`.

The selected first source is AXI `ARLEN` with width `8`, encoding
`axlen-plus-one`, transaction-request capture, required `max-beats` in range
`1..256`, and `validation report-only`.

The selection did not generate counters, storage, full read-data reassembly,
per-beat outputs, all-beat `RRESP` aggregation, or per-ID queues. The
follow-up `.63` slice shipped parser/report metadata and static validation for
the selected `burst-length` contract. The active frontier is now
`IAL2-FEATURE-COMPLETENESS-FRONTIER.64`, the next exact-owner selector after
report-only burst-length metadata.
