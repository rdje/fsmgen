---
id: ial2-post-axi-aw-w-composition-next-increment-selection
title: The next AXI initiator increment is a bounded full single-beat write transactor
answers:
  - "what comes after the shipped AXI AW W request composition?"
  - "what did IAL2-AXI-MANAGER-INITIATOR-FRONTIER.19 select?"
  - "why is AXI AW W B composition selected next?"
  - "why is AXI capacity status integration deferred?"
  - "what is IAL2-AXI-MANAGER-INITIATOR-FRONTIER.20?"
date: 2026-07-23
status: current
tags: [ial2, axi, initiator, aw, w, b, composition, transactor, single-beat, task-tree]
evidence: docs/IAL2_AXI_MANAGER_INITIATOR_POST_AW_W_COMPOSITION_NEXT_INCREMENT_SELECTION.md; docs/knowledge/ial2-axi-aw-w-request-composition-first-slice.md; docs/knowledge/ial2-axi-b-response-acceptor-first-slice.md; docs/knowledge/ial2-axi-manager-response-demux-readiness-audit.md; docs/decisions/0020-ial2-layered-composable-transactor-roles.md; docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md
reverify: rg -n 'full-write transactor|response-aware coordinator|IAL2-AXI-MANAGER-INITIATOR-FRONTIER\.19|IAL2-AXI-MANAGER-INITIATOR-FRONTIER\.20' docs/IAL2_AXI_MANAGER_INITIATOR_POST_AW_W_COMPOSITION_NEXT_INCREMENT_SELECTION.md docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md
---

`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.19` selects a bounded single-beat
AW+W+B full-write transactor composition. It reuses the shipped AW driver, W
driver, B acceptor, and request coordination behavior without changing or
duplicating their channel state machines. A new response-aware coordinator and
structural full-write top will relate one admitted aligned request to exactly
one accepted B response and one full-transaction completion event.

The existing AW+W `write_done` remains request-channel issue completion and
must not be redefined. `.20` is a behavior-neutral readiness audit that must
choose nested versus direct-child C4 topology, B-arm timing, retained-AWID to
captured-BID correlation, BRESP/error exposure, aggregate busy lifetime,
request-done versus transaction-done signals, artifact/report contracts, and
the generated-HDL proof matrix before public contract selection.

Capacity/status integration is deferred because its `write-submit` and
`write-complete` events are abstract and its optional ID/lifecycle/ordering/
response-demux families require a separate adapter and outstanding policy. AR/R
would open a new direction; multi-beat W requires dynamic AW metadata, beat and
WLAST sequencing, and address/lane coupling. Decision `0020` remains a
director-gated future horizon and is not activated by this PNT selection.
