---
id: ial2-two-dynamic-one-static-mixed-read-rlast-recapture-contract-selection
title: Two-dynamic one-static mixed read RLAST recapture contract selection
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.430 select?"
  - "what is the public contract for two-dynamic mixed read RLAST recapture?"
  - "what should implement two-dynamic-plus-one-static mixed read burst-last recapture?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, mixed-dynamic-static, read, rlast, recapture, contract]
evidence: docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.430|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.431|TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_CONTRACT_SELECTION|mixed_dynamic_static_multi_active_dynamic_read|generated_multi_mixed_dynamic_static_read_demux_last_beat_completion' docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.430` selects `.431`, direct
implementation of two-dynamic-plus-one-static mixed dynamic/static read
burst-last `RID && RLAST` same-cycle release-and-recapture for the existing
public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last.ppif`.

The selector changes no behavior. It preserves public syntax, support
identity, `bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`,
`response_scope: burst_last`, `last_signal: axi0_rlast`, final-beat
completion source `generated_multi_mixed_dynamic_static_read_demux_last_beat`,
raw non-final `RID` ownership assertions, generated final-beat completions,
and adjacent read-data/raw-`ARLEN`/runtime/multi-beat consumers.

The selected implementation contract adds recapture fields for `r0` and `r1`
under `dynamic_capture.transactions[]` with policy
`mixed_dynamic_static_multi_active_dynamic_read`, adds list-shaped
`static_capture[]` for `r2`, uses
`generated_multi_mixed_dynamic_static_read_demux_last_beat_completion` as the
release-recapture source, composes dynamic/static guards from the existing
`.427` read-side guard storage, and replaces only the `r0`/`r1`/`r2`
request-not-busy assertions with idle-or-releasing assertions.
