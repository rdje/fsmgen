---
id: ial2-dynamic-same-id-reject-enforcement-mapping-behavior
title: Dynamic same-ID reject maps to generated multi-active demux assertions
answers:
  - "does dynamic-id-reuse reject now map to generated assertions?"
  - "which sample covers dynamic same-ID reject response-demux mapping?"
  - "does .438 add new HDL behavior?"
  - "what report fields prove generated dynamic same-ID reject enforcement?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, response-demux, behavior]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_REJECT_ENFORCEMENT_MAPPING_BEHAVIOR.md; ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi_same_id_reject.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.438|DYNAMIC_SAME_ID_REJECT_ENFORCEMENT_MAPPING_BEHAVIOR|dynamic_read_response_demux_multi_same_id_reject|generated_no_active_same_id_reject|generated_no_active_same_id_assertions|response_demux_covered' docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_REJECT_ENFORCEMENT_MAPPING_BEHAVIOR.md ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi_same_id_reject.ppif perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm t/1436-ial2-ppif-parser-cli.t t/1437-axi-ial2-manager-capacity-status-generator.t t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.438` maps selected
`(dynamic-id-reuse reject)` policy to already generated multi-active dynamic
response-demux assertion artifacts.

Covered reports now use `implementation_status:
generated_no_active_same_id_reject`, `enforcement:
generated_no_active_same_id_assertions`, `assertion_enforcement:
runtime_assertion`, `response_demux_covered: true`, and the exact generated
no-active-same-ID plus active-ID uniqueness assertion names.

The new support-accounted public sample is
`ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi_same_id_reject.ppif`.
It has the same generated IAL1/IAL0/HDL artifacts as the base multiple dynamic
read response-demux sample; only acceptance, report metadata, and residue
movement change.

Single-active dynamic demux, one-dynamic mixed demux, dynamic queues,
scoreboards, direct backend behavior, backend-language variants, and VHDL
remain future exact-owner work.
