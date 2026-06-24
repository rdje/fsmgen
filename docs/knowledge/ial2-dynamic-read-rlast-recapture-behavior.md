---
id: ial2-dynamic-read-rlast-recapture-behavior
title: Dynamic read burst-last recapture behavior is generated
answers:
  - "did dynamic read RLAST recapture ship?"
  - "how does single-active dynamic read RLAST release-and-recapture work?"
  - "what report fields identify dynamic read RLAST recapture?"
  - "does dynamic read RLAST recapture preserve read-data consumers?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, read, rlast, recapture, behavior]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_RECAPTURE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_RECAPTURE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_TRANSACTION_ID_CAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_BURST_LENGTH_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_RUNTIME_VALIDATION_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_MULTI_BEAT_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.372|DYNAMIC_READ_RLAST_RECAPTURE_BEHAVIOR|generated_dynamic_demux_last_beat_completion|axi0_r0_dynamic_id_release_recapture|axi0_r0_dynamic_request_idle_or_releasing|bounded_dynamic_read_rid_rlast_demux_contract' docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_RECAPTURE_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1437-axi-ial2-manager-capacity-status-generator.t t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.372` ships generated same-cycle
release-and-recapture for the single-active dynamic read burst-last `RID &&
RLAST` response-demux sample
`ppif/axi_manager_capacity_status_dynamic_read_response_demux_burst_last.ppif`.

The public source syntax, support identity, and
`bounded_dynamic_read_rid_rlast_demux_contract` mode are unchanged.

FSMGen now emits `axi0_r0_dynamic_id_release_recapture`, keeps release-only
disjoint from same-cycle requests, reports
`same_cycle_release_recapture_policy: single_active_dynamic_read` with
`release_recapture_source: generated_dynamic_demux_last_beat_completion`, and
replaces the single-active burst-last request-not-busy assertion with
`axi0_r0_dynamic_request_idle_or_releasing`.

Matched non-last beats remain raw matched read beats only: they do not pulse
completion, release, or recapture. Scalar last-beat read-data, raw-`ARLEN`,
runtime beat-count/`RLAST`, and multi-beat output-bank payload/validation
contracts remain preserved consumers of the shared response-demux state.
