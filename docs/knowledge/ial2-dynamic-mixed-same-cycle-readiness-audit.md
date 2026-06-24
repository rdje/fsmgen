---
id: ial2-dynamic-mixed-same-cycle-readiness-audit
title: Dynamic and mixed same-cycle audit selects single-active dynamic write contract
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.363 decide?"
  - "what comes after the same-cycle readiness audit?"
  - "why is single-active dynamic write recapture first?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.364?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, same-cycle, recapture, selector]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_MIXED_SAME_CYCLE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_TRANSACTION_ID_CAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.363|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.364|DYNAMIC_MIXED_SAME_CYCLE_READINESS_AUDIT|dynamic_id_capture|dynamic_id_release|same-cycle release-and-recapture|bounded_dynamic_write_bid_demux_contract' docs/AXI_IAL2_MANAGER_DYNAMIC_MIXED_SAME_CYCLE_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_TRANSACTION_ID_CAPTURE_BEHAVIOR.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.363` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.364`, public contract selection for the
first single-active dynamic write `BID` same-cycle release-and-recapture
boundary.

The audit found that capacity admission already accounts for same-cycle
completion fan-in, but generated dynamic/mixed response-demux state still
requires `!busy` on capture and releases busy through a separate completion
rule. A request for a still-busy slot in the same cycle as that slot's
generated completion is therefore not shipped behavior.

Single-active dynamic write is the smallest first owner because it has one
dynamic selected-ID/busy slot, no sibling onehot0 request widening, no static
concrete-ID exclusion, no `RID`/`RLAST`, and no read-data payload dependency.
Static recapture, mixed dynamic/static request widening, read-side recapture,
read-data capture, queues, scoreboards, direct backend, backend-language
variants, VHDL, and full AXI manager behavior remain later exact owners.
