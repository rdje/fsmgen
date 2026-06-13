---
id: ial2-axi-manager-post-last-beat-read-data-next-slice-selection
title: AXI post last-beat read-data selector chooses beat-count and depth contract selection
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.61 select?"
  - "what comes after generated last-beat read-data capture?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.61?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.62?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.62?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.63?"
  - "why is beat-count or depth selected before full read-data reassembly?"
date: 2026-06-13
status: current
tags: [ial2, axi, manager, read-data, burst, beat-count, depth, arlen, selector, task-tree]
evidence: docs/AXI_IAL2_MANAGER_POST_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_BEHAVIOR_FIRST_SLICE.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.62|beat-count/depth|AXI_IAL2_MANAGER_POST_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION' docs/AXI_IAL2_MANAGER_POST_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.61` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.62`: public AXI burst read-data
beat-count/depth contract selection.

The selection follows generated last-beat `RDATA`/`RRESP` capture. Full
multi-beat read-data reassembly, per-beat outputs, all-beat `RRESP`
aggregation, missing/extra beat validation, and per-ID reassembly need an
explicit expected-count or bounded-depth contract before parser/report
metadata or generated behavior can honestly ship.

`.62` selected an ARLEN-based `burst-length` clause with width-8
`axlen-plus-one` encoding, transaction-request capture, required `max-beats`,
and report-only validation. The active frontier is `.63`, parser/report
metadata and static validation for that contract.
