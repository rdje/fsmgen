---
id: ial2-single-active-dynamic-same-id-reject-mapping-behavior
title: Single-active dynamic same-ID reject maps to idle-or-releasing demux assertions
answers:
  - "does single-active dynamic-id-reuse reject now map to generated assertions?"
  - "which sample covers single-active dynamic same-ID reject response-demux mapping?"
  - "what report fields prove single-active dynamic same-ID reject enforcement?"
  - "does .442 add new generated HDL behavior?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, response-demux, behavior]
evidence: docs/AXI_IAL2_MANAGER_SINGLE_ACTIVE_DYNAMIC_SAME_ID_REJECT_MAPPING_BEHAVIOR.md; ppif/axi_manager_capacity_status_dynamic_read_response_demux_same_id_reject.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.442|SINGLE_ACTIVE_DYNAMIC_SAME_ID_REJECT_MAPPING_BEHAVIOR|dynamic_read_response_demux_same_id_reject|generated_single_active_reject|generated_idle_or_releasing_assertions|single_active_covered|single_active_request_policy' docs/AXI_IAL2_MANAGER_SINGLE_ACTIVE_DYNAMIC_SAME_ID_REJECT_MAPPING_BEHAVIOR.md ppif/axi_manager_capacity_status_dynamic_read_response_demux_same_id_reject.ppif perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm t/1436-ial2-ppif-parser-cli.t t/1437-axi-ial2-manager-capacity-status-generator.t t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.442` maps selected
`(dynamic-id-reuse reject)` policy to existing generated single-active dynamic
response-demux assertion artifacts for write `BID`, read single-beat `RID`,
and read burst-last `RID && RLAST`.

Covered reports use `implementation_status: generated_single_active_reject`,
`enforcement: generated_idle_or_releasing_assertions`,
`assertion_enforcement: runtime_assertion`, `response_demux_covered: true`,
`single_active_covered: true`, and `single_active_request_policy:
idle_or_releasing`, plus exact idle-or-releasing, active-match, and
completion-active assertion names.

The support-accounted public sample is
`ppif/axi_manager_capacity_status_dynamic_read_response_demux_same_id_reject.ppif`.
It has the same generated IAL1/IAL0/HDL behavior as the base single-active
dynamic read response-demux sample; only acceptance, report metadata, and
residue movement change.

One-dynamic mixed response-demux, dynamic queues, scoreboards, direct backend
behavior, backend-language variants, and VHDL remain future exact-owner work.
