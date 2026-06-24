---
id: ial2-dynamic-read-same-cycle-recapture-contract-selection
title: Single-active dynamic read single-beat same-cycle recapture contract selected
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.367 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.368?"
  - "does dynamic read same-cycle recapture cover RLAST first?"
  - "what is the first dynamic read recapture behavior?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, read, same-cycle, recapture, contract]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_CYCLE_RECAPTURE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_POST_DYNAMIC_WRITE_RECAPTURE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_TRANSACTION_ID_CAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_TRANSACTION_ID_CAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_SAME_CYCLE_RECAPTURE_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; ppif/axi_manager_capacity_status_dynamic_read_response_demux.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.367|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.368|DYNAMIC_READ_SAME_CYCLE_RECAPTURE_CONTRACT_SELECTION|single_active_dynamic_read|bounded_dynamic_read_rid_demux_contract|axi0_r0_dynamic_request_idle_or_releasing' docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_CYCLE_RECAPTURE_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.367` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.368`, direct generated behavior for
single-active dynamic read single-beat `RID` same-cycle release-and-recapture.

The selector changes no parser, generator, PPIF sample, support accounting,
validation behavior, generated artifact, test, JSON, or HDL behavior.

The first read recapture owner reuses
`ppif/axi_manager_capacity_status_dynamic_read_response_demux.ppif`; no new
PPIF syntax marker is required. It keeps
`bounded_dynamic_read_rid_demux_contract`, adds read-side
`same_cycle_release_recapture_policy: single_active_dynamic_read`, and should
replace the single-active request-not-busy assertion with
`axi0_r0_dynamic_request_idle_or_releasing`.

Burst-last `RID && RLAST` recapture is intentionally not first because it
touches last-beat lifetime, scalar last-beat read-data, burst-length/runtime
validation, and multi-beat output-bank consumers. Those remain later exact
owners.
