---
id: ial2-post-multiple-dynamic-read-recapture-next-slice-selection
title: Multiple dynamic read burst-last recapture readiness selected after single-beat recapture
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.382 select?"
  - "what follows multiple dynamic read single-beat recapture?"
  - "is multiple dynamic read burst-last recapture next?"
  - "why is multiple dynamic read burst-last recapture audited first?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, read, rlast, recapture, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_READ_RECAPTURE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RECAPTURE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_RUNTIME_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_MULTI_BEAT_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.382|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.383|POST_MULTIPLE_DYNAMIC_READ_RECAPTURE_NEXT_SLICE_SELECTION|multiple all-dynamic read burst-last|bounded_multi_dynamic_read_rid_rlast_demux_contract|generated_dynamic_demux_last_beat_completion' docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_READ_RECAPTURE_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.382` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.383`, a readiness audit for multiple
all-dynamic read burst-last `RID && RLAST` same-cycle release-and-recapture.

The selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, JSON, HDL, or runtime
behavior.

The burst-last audit is next because it is the closest remaining all-dynamic
read sibling after `.381` shipped single-beat recapture. It must be audited
before contract or implementation work because final `RID && RLAST`
completion, non-final raw read beats, scalar last-beat read-data, raw
`ARLEN`, runtime beat-count/`RLAST`, and multi-beat output banks all consume
the same selected-ID/busy lifetime in different ways.

Mixed dynamic/static recapture, static busy recapture, request arbitration
beyond onehot0, dynamic same-ID queues, scoreboards, backend variants, VHDL,
and full AXI manager behavior remain future exact-owner work.
