---
id: ial2-post-multiple-dynamic-write-recapture-next-slice-selection
title: Multiple dynamic read single-beat recapture contract selected after multiple dynamic write recapture
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.379 select?"
  - "what follows multiple dynamic write same-cycle recapture?"
  - "is multiple dynamic read single-beat recapture next?"
  - "why is burst-last multiple dynamic read recapture deferred?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, read, recapture, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_WRITE_RECAPTURE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_WRITE_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_MULTI_BEAT_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.379|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.380|POST_MULTIPLE_DYNAMIC_WRITE_RECAPTURE_NEXT_SLICE_SELECTION|multiple all-dynamic read single-beat|bounded_multi_dynamic_read_rid_demux_contract|multi_active_unique_dynamic_read' docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_WRITE_RECAPTURE_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.379` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.380`, public contract selection for
multiple all-dynamic read single-beat `RID` same-cycle release-and-recapture.

The selector changes no parser, generator, PPIF sample, support accounting,
validation behavior, generated artifact, test, JSON, HDL, or runtime behavior.

Single-beat multiple dynamic read is next because it is the closest read-side
counterpart to the shipped multiple dynamic write recapture behavior: it uses
the same multi-active selected-ID/busy lifecycle, onehot0 request policy,
active-ID uniqueness, request no-active-same-ID, response active/unique-match,
and completion-active assertion structure without `RLAST` final-beat coupling.

Multiple dynamic read burst-last recapture remains deferred because it must
preserve matched non-final beats, final-only completion/release, scalar
last-beat read-data, report-only raw-`ARLEN`, runtime beat-count/`RLAST`, and
multi-beat output-bank consumers.
