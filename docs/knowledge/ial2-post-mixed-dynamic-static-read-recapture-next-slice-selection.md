---
id: ial2-post-mixed-dynamic-static-read-recapture-next-slice-selection
title: Mixed read burst-last recapture readiness follows mixed read single-beat recapture
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.393 select?"
  - "what comes after mixed dynamic/static read single-beat recapture?"
  - "is mixed read burst-last recapture next after .392?"
  - "why choose a mixed read RLAST recapture readiness audit?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, mixed-dynamic-static, read, rlast, recapture, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_BURST_LENGTH_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.393|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.394|POST_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_NEXT_SLICE_SELECTION|mixed dynamic/static read burst-last `RID && RLAST` same-cycle release-and-recapture readiness|bounded_mixed_dynamic_static_read_rid_rlast_demux_contract|generated_mixed_dynamic_static_read_demux_last_beat' docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.393` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.394`, readiness audit for mixed
dynamic/static read burst-last `RID && RLAST` same-cycle
release-and-recapture.

The next owner follows `.392`, which shipped mixed dynamic/static read
single-beat `RID` recapture and confirmed the burst-last public sample still
has no recapture metadata or `static_capture` report block. Burst-last is the
nearest sibling, but it needs a readiness audit before contract selection
because final-only release on `RID && RLAST` must preserve raw non-final
`RID` beats, raw active/unique-match assertions, scalar last-beat read-data,
raw `ARLEN`, runtime beat-count/`RLAST` validation, and multi-beat output-bank
consumers.

`.393` changes no parser, generator, PPIF sample, support-accounting catalog,
validation behavior, test, schedule/check/semantic JSON, HDL, or runtime
behavior.
