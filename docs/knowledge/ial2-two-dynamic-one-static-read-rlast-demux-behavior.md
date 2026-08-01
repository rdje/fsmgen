---
id: ial2-two-dynamic-one-static-read-rlast-demux-behavior
title: Two-dynamic/one-static mixed read burst-last response-demux behavior shipped
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.347 ship?"
  - "is two-dynamic-plus-static mixed read RLAST demux implemented?"
  - "is two-dynamic-plus-static mixed read burst-last response-demux implemented?"
  - "which sample implements two-dynamic-plus-static mixed read burst-last response demux?"
date: 2026-06-24
status: current
tags: [ial2, axi, dynamic-id, static-id, read-response-demux, rlast, behavior]
evidence: docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: >-
  rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.347|TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR|axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last|bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract|generated_multi_mixed_dynamic_static_read_demux_last_beat|mixed_dynamic_static_read_rlast_demux_multi_dynamic|matched_dynamic_or_static_concrete_id_and_last_signal' docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last.ppif perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
  t/248-regression-corpus-accounting.t docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.347` ships generated bounded
two-dynamic-plus-one-static mixed dynamic/static read burst-last `RID`/`RLAST`
response-demux behavior.

The support-accounted public sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last.ppif`.
It uses dynamic read transactions `r0`/`r1`, concrete static read transaction
`r2` at ID `3`, `response-scope burst-last`, one-bit last signal
`axi0_rlast`, and generated completions.

The report mode is
`bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract` with
completion source `generated_multi_mixed_dynamic_static_read_demux_last_beat`
and semantics `matched_dynamic_or_static_concrete_id_and_last_signal`.
Dynamic capture keeps ownership `multi_mixed_dynamic_static_unique_read_ids`,
same-cycle policy `onehot0_mixed_read_request`, same-ID conflict policy
`active_dynamic_ids_must_be_unique`, and static exclusion `4'd3`.

Raw accepted read response-beat ownership assertions match by `RID` without
`RLAST`; generated completions and busy release require final `RID && RLAST`.
Read-data, raw `ARLEN`, runtime validation, and multi-beat output-bank behavior
over this two-dynamic/one-static mixed read burst-last demux remain future
exact-owner work. The follow-on readiness audit was
`IAL2-FEATURE-COMPLETENESS-FRONTIER.348`.
