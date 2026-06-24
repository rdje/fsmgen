---
id: ial2-dynamic-write-same-cycle-recapture-contract-selection
title: Single-active dynamic write same-cycle recapture contract selected
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.364 select?"
  - "what is the first same-cycle recapture behavior?"
  - "does dynamic write same-cycle recapture need new PPIF syntax?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.365?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, write, same-cycle, recapture, contract]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_SAME_CYCLE_RECAPTURE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_MIXED_SAME_CYCLE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_TRANSACTION_ID_CAPTURE_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; ppif/axi_manager_capacity_status_dynamic_write_response_demux.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.364|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.365|DYNAMIC_WRITE_SAME_CYCLE_RECAPTURE_CONTRACT_SELECTION|same_cycle_release_recapture_policy|single_active_dynamic_write|bounded_dynamic_write_bid_demux_contract' docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_SAME_CYCLE_RECAPTURE_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.364` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.365`, direct generated behavior for
single-active dynamic write `BID` same-cycle release-and-recapture.

The selected first behavior reuses
`ppif/axi_manager_capacity_status_dynamic_write_response_demux.ppif`; no new
PPIF syntax marker is required. The report should preserve
`bounded_dynamic_write_bid_demux_contract` and add explicit same-cycle
vocabulary such as
`same_cycle_release_recapture_policy: single_active_dynamic_write`.

The selected behavior captures a new `AWID` when a write request occurs in the
same cycle as the generated matching `BID` completion for the active dynamic
slot, while the completion still matches the pre-update selected ID and busy
state. Multiple dynamic, mixed dynamic/static, static busy, read `RID`/`RLAST`,
read-data, queues, scoreboards, direct backend, backend-language variants,
VHDL, and full AXI manager behavior remain later exact owners.
