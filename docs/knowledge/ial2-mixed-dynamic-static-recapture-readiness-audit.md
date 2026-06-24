---
id: ial2-mixed-dynamic-static-recapture-readiness-audit
title: Mixed dynamic/static recapture should start with write BID contract selection
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.387 decide?"
  - "which mixed dynamic/static recapture task comes after .387?"
  - "why start mixed dynamic/static recapture with write BID?"
  - "is mixed dynamic/static recapture implemented after .387?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, mixed-dynamic-static, recapture, readiness]
evidence: docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_RECAPTURE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_READ_RLAST_RECAPTURE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_READINESS_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.387|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.388|MIXED_DYNAMIC_STATIC_RECAPTURE_READINESS_AUDIT|mixed dynamic/static write BID same-cycle release-and-recapture|bounded_mixed_dynamic_static_write_bid_demux_contract' docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_RECAPTURE_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.387` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.388`, public contract selection for mixed
dynamic/static write `BID` same-cycle release-and-recapture.

The audit found that current mixed write/read/read-RLAST samples still report
request-not-busy assertions and no release-recapture metadata. Mixed
dynamic/static has enough substrate for a contract selector because dynamic
states already own selected-ID plus busy storage, static states already own
concrete-ID busy storage, and mixed assertions already cover onehot0 request,
static-ID reservation, active-match, unique-match, and completion-active
rules. It is not ready for direct behavior because static release-and-recapture
semantics and report vocabulary are not yet pinned.

Mixed write is selected first because it exercises both dynamic selected-ID
recapture and static concrete busy recapture without the read-side
`RID`/`RLAST`, read-data, raw-`ARLEN`, runtime validation, and multi-beat
output-bank preservation stack. `.387` changes no parser, generator, PPIF
sample, support accounting, tests, schedule/check/semantic JSON, HDL, or
runtime behavior.
