---
id: ial2-post-multiple-dynamic-read-rlast-recapture-next-slice-selection
title: Mixed dynamic/static recapture audit follows multiple dynamic read RLAST recapture
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.386 select?"
  - "what comes after multiple dynamic read RLAST recapture?"
  - "when should mixed dynamic/static recapture be audited?"
  - "why not implement mixed dynamic/static recapture directly after .385?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, mixed-dynamic-static, recapture, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_READ_RLAST_RECAPTURE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_WRITE_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_READINESS_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.386|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.387|POST_MULTIPLE_DYNAMIC_READ_RLAST_RECAPTURE_NEXT_SLICE_SELECTION|mixed dynamic/static same-cycle release-and-recapture|mixed dynamic/static recapture readiness' docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_READ_RLAST_RECAPTURE_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.386` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.387`, a readiness audit for mixed
dynamic/static same-cycle release-and-recapture.

The selector follows `.385`, which completed the all-dynamic read burst-last
recapture sibling. Mixed dynamic/static recapture is now the closest remaining
same-cycle lifecycle shape, but it should be audited before behavior because
static transactions own concrete-ID busy state rather than selected-ID state,
dynamic requests must remain excluded from selected static concrete IDs, and
read burst-last plus read-data/raw-`ARLEN`/runtime/multi-beat consumers have
preservation implications.

`.386` changes no parser, generator, PPIF sample, support accounting, tests,
schedule/check/semantic JSON, HDL, or runtime behavior. The next owner must
decide whether the first mixed behavior should be mixed write, mixed read
single-beat, mixed read burst-last, static-busy-only recapture, a validation
retry, support-detail/report cleanup, or a narrower prerequisite.
