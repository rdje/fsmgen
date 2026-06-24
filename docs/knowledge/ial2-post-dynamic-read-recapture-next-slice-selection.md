---
id: ial2-post-dynamic-read-recapture-next-slice-selection
title: Burst-last dynamic read recapture readiness audit selected after single-beat recapture
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.369 select?"
  - "what follows single-active dynamic read single-beat recapture?"
  - "is dynamic read burst-last recapture next?"
  - "why not implement dynamic read RLAST recapture directly?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, read, rlast, recapture, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_RECAPTURE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_CYCLE_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_TRANSACTION_ID_CAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_BURST_LENGTH_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_RUNTIME_VALIDATION_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_MULTI_BEAT_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.369|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.370|POST_DYNAMIC_READ_RECAPTURE_NEXT_SLICE_SELECTION|burst-last `RID && RLAST`|axi0_r0_dynamic_request_not_busy|single_active_dynamic_read' docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_RECAPTURE_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.369` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.370`, readiness audit for single-active
dynamic read burst-last `RID && RLAST` same-cycle release-and-recapture after
`.368` shipped single-beat dynamic read recapture.

The selector changes no parser, generator, PPIF sample, support accounting,
validation behavior, generated artifact, test, JSON, or HDL behavior.

Burst-last read recapture is the closest remaining read-side sibling, but it is
not selected for direct implementation yet because it touches final-beat
completion, matched non-last beats, raw active-match assertions, scalar
last-beat read-data, report-only raw-`ARLEN`, runtime beat-count/`RLAST`, and
multi-beat output-bank consumers.

Multiple dynamic request widening, mixed dynamic/static recapture, static busy
recapture, dynamic same-ID queues, scoreboards, backend variants, VHDL, and
full-manager behavior remain later owners.
