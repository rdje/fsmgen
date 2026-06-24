---
id: ial2-post-mixed-dynamic-static-write-recapture-next-slice-selection
title: Mixed read single-beat recapture contract follows mixed write recapture
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.390 select?"
  - "what comes after mixed dynamic/static write recapture?"
  - "why choose mixed read single-beat recapture after mixed write recapture?"
  - "is mixed read burst-last recapture next after .389?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, mixed-dynamic-static, read, recapture, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_RECAPTURE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.390|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.391|POST_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_NEXT_SLICE_SELECTION|mixed dynamic/static read single-beat `RID` same-cycle release-and-recapture|bounded_mixed_dynamic_static_read_rid_demux_contract' docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.390` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.391`, public contract selection for mixed
dynamic/static read single-beat `RID` same-cycle release-and-recapture.

The selector follows `.389`, which shipped mixed dynamic/static write `BID`
same-cycle release-and-recapture and pinned the shared dynamic/static
recapture vocabulary. Single-beat read is the next smallest owner because it
can adapt that vocabulary to `response_demux.read` while preserving
`bounded_mixed_dynamic_static_read_rid_demux_contract`,
`response_scope: single_beat`, and
`generated_mixed_dynamic_static_read_demux`.

Mixed read burst-last recapture remains deferred until the single-beat read
contract is selected, because burst-last also has to preserve final-only
`RID && RLAST` completion, raw non-final read beat assertions, scalar
last-beat read-data, raw `ARLEN`, runtime beat-count/`RLAST` validation, and
multi-beat output-bank consumers. `.390` changes no parser, generator, PPIF
sample, support accounting, tests, schedule/check/semantic JSON, HDL, or
runtime behavior.
