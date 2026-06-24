---
id: ial2-dynamic-read-rlast-recapture-contract-selection
title: Dynamic read burst-last recapture contract selects direct behavior
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.371 select?"
  - "what is the dynamic read RLAST recapture contract?"
  - "which source sample owns single-active dynamic read RLAST recapture?"
  - "what release_recapture_source should dynamic read RLAST recapture report?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, read, rlast, recapture, contract]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_RECAPTURE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_RECAPTURE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_CYCLE_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_TRANSACTION_ID_CAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_BURST_LENGTH_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_RUNTIME_VALIDATION_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_MULTI_BEAT_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.371|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.372|DYNAMIC_READ_RLAST_RECAPTURE_CONTRACT_SELECTION|generated_dynamic_demux_last_beat_completion|axi0_r0_dynamic_request_idle_or_releasing|bounded_dynamic_read_rid_rlast_demux_contract' docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_RECAPTURE_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.371` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.372`, direct generated behavior for
single-active dynamic read burst-last `RID && RLAST` same-cycle
release-and-recapture.

The selected public shape reuses
`ppif/axi_manager_capacity_status_dynamic_read_response_demux_burst_last.ppif`
and preserves `bounded_dynamic_read_rid_rlast_demux_contract`.

The selected report vocabulary reuses
`same_cycle_release_recapture_policy: single_active_dynamic_read`, adds
`axi0_r0_dynamic_id_release_recapture`, and reports
`release_recapture_source: generated_dynamic_demux_last_beat_completion`.

The behavior owner must preserve raw matched non-last beats, raw active-match
assertions, scalar last-beat read-data, raw-`ARLEN`, runtime beat-count/`RLAST`,
and multi-beat output-bank payload/validation contracts while changing only
the shared single-active burst-last response-demux selected-ID lifetime and
assertion/report vocabulary.
