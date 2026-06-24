---
id: ial2-three-static-mixed-dynamic-static-read-rlast-recapture-contract-selection
title: Three-static mixed read RLAST recapture contract selection
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.422 select?"
  - "what is the three-static mixed read RLAST recapture contract?"
  - "what should IAL2-FEATURE-COMPLETENESS-FRONTIER.423 implement?"
  - "what remains deferred after three-static mixed read RLAST recapture selection?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, mixed-dynamic-static, read, rlast, recapture, selection]
evidence: docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_CONTRACT_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.422|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.423|THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_CONTRACT_SELECTION|multi_static3_burst_last|generated_multi_mixed_dynamic_static_read_demux_last_beat_completion|axi0_r3_static_busy_release_recapture|axi0_r3_static_request_idle_or_releasing|one dynamic plus two or three static states' docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.422` selects `.423`, direct
implementation of one-dynamic-plus-three-static mixed dynamic/static read
burst-last `RID && RLAST` same-cycle release-and-recapture for the existing
public sample:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last.ppif
```

The selector changes no behavior. It preserves public syntax/support identity,
`bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`,
`response_scope: burst_last`, one-bit `axi0_rlast`,
`generated_multi_mixed_dynamic_static_read_demux_last_beat`, final-beat
completion semantics, `r0`/`r1`/`r2`/`r3` transaction lists, static ID
reservations for `4'd3`/`4'd5`/`4'd7`, generated demux rules/completions, raw
non-final `RID` ownership evidence, and adjacent read-data consumers.

`.423` must add dynamic recapture under
`dynamic_capture.transactions[0]`, list-shaped `static_capture[]` entries for
`r1`/`r2`/`r3`, release-recapture source
`generated_multi_mixed_dynamic_static_read_demux_last_beat_completion`,
dynamic/static guard composition, release-only same-transaction request
exclusions, and idle-or-releasing assertions for all four transactions.

The implementation boundary is narrow: widen only the burst-last multi-mixed
read recapture selection from exactly one dynamic plus two static states to
exactly one dynamic plus two or three static states, and update the focused
RLAST report expectation helper accordingly.

Two-dynamic-plus-one-static read recapture, static-busy-only recapture outside
selected samples, broader request arbitration, dynamic same-ID queues,
scoreboards, queued/blocking policy, direct backend behavior, backend-language
variants, VHDL, and full AXI manager behavior remain deferred.
