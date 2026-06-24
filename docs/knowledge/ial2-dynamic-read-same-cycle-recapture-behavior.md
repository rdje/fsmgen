---
id: ial2-dynamic-read-same-cycle-recapture-behavior
title: Single-active dynamic read single-beat same-cycle recapture behavior shipped
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.368 ship?"
  - "does single-active dynamic read single-beat recapture ship?"
  - "what is the generated dynamic read recapture rule?"
  - "what assertion replaced dynamic read request-not-busy?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, read, same-cycle, recapture, behavior]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_CYCLE_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_CYCLE_RECAPTURE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_TRANSACTION_ID_CAPTURE_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; ppif/axi_manager_capacity_status_dynamic_read_response_demux.ppif; ppif/axi_manager_capacity_status_dynamic_read_data.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.368|DYNAMIC_READ_SAME_CYCLE_RECAPTURE_BEHAVIOR|axi0_r0_dynamic_id_release_recapture|single_active_dynamic_read|axi0_r0_dynamic_request_idle_or_releasing|bounded_dynamic_read_rid_demux_contract' docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_CYCLE_RECAPTURE_BEHAVIOR.md docs/AXI_IAL2_MANAGER_DYNAMIC_READ_TRANSACTION_ID_CAPTURE_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1437-axi-ial2-manager-capacity-status-generator.t t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.368` ships generated single-active dynamic
read single-beat `RID` same-cycle release-and-recapture for
`ppif/axi_manager_capacity_status_dynamic_read_response_demux.ppif`.

The public syntax and support-accounting identity are unchanged. The generated
response-demux mode remains `bounded_dynamic_read_rid_demux_contract`.

FSMGen now emits `axi0_r0_dynamic_id_release_recapture` for the same-cycle path,
keeps `axi0_r0_dynamic_id_release` guarded by no same-cycle `axi0_r0_request`,
reports `same_cycle_release_recapture_policy: single_active_dynamic_read`, and
replaces `axi0_r0_dynamic_request_not_busy` with
`axi0_r0_dynamic_request_idle_or_releasing` for this single-active read shape.

The raw response match still uses the pre-update captured ID and busy state.
The scalar single-beat dynamic read-data sample remains a preservation consumer
of the generated completion pulse; `.368` does not add payload recapture
semantics.

Burst-last `RID && RLAST` recapture, scalar last-beat read-data recapture,
burst-length/runtime/multi-beat recapture, multiple dynamic request widening,
mixed dynamic/static recapture, static busy recapture, dynamic same-ID queues,
scoreboards, backend variants, VHDL, and full-manager behavior remain later
owners.
