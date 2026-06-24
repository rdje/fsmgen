---
id: ial2-two-dynamic-one-static-read-rlast-demux-contract
title: Two-dynamic/one-static mixed read burst-last response-demux contract selected
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.346 select?"
  - "what is the contract for two-dynamic-plus-static mixed read RLAST demux?"
  - "which PPIF sample stem is selected for two-dynamic-plus-static mixed read burst-last response demux?"
date: 2026-06-24
status: superseded
tags: [ial2, axi, dynamic-id, static-id, read-response-demux, rlast, contract]
evidence: docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_READINESS_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.346|IAL2-FEATURE-COMPLETENESS-FRONTIER\.347|TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_CONTRACT_SELECTION|axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last|bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract|generated_multi_mixed_dynamic_static_read_demux_last_beat|mixed_dynamic_static_read_rlast_demux_multi_dynamic|matched_dynamic_or_static_concrete_id_and_last_signal' docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.346` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.347`, direct generated behavior for
bounded two-dynamic-plus-one-static mixed dynamic/static read burst-last
`RID`/`RLAST` response-demux.

The selected public sample stem is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last.ppif`.
It should use dynamic read transactions `r0`/`r1`, concrete static read
transaction `r2` at ID `3`, `response-scope burst-last`, one-bit last signal
`axi0_rlast`, and generated completions.

The selected report mode is
`bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract` with
completion source `generated_multi_mixed_dynamic_static_read_demux_last_beat`
and semantics `matched_dynamic_or_static_concrete_id_and_last_signal`.
Dynamic capture keeps ownership `multi_mixed_dynamic_static_unique_read_ids`,
same-cycle policy `onehot0_mixed_read_request`, same-ID conflict policy
`active_dynamic_ids_must_be_unique`, and static exclusion `4'd3`.

Raw accepted read response-beat ownership assertions must match by `RID`
without `RLAST`; generated completions and busy release must additionally
require final `RID && RLAST`. `.346` changes no parser, generator, PPIF
sample, support-accounting, test, JSON, or HDL behavior.
