---
id: ial2-one-dynamic-mixed-dynamic-same-id-reject-mapping-behavior
title: One-dynamic mixed dynamic same-ID reject maps to static-ID exclusion assertions
answers:
  - "does one-dynamic mixed dynamic-id-reuse reject now map to generated assertions?"
  - "what report fields prove one-dynamic mixed dynamic same-ID reject enforcement?"
  - "does .446 add generated HDL behavior or a new public sample?"
  - "which mixed dynamic/static shapes does .446 cover?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, response-demux, behavior]
evidence: docs/AXI_IAL2_MANAGER_ONE_DYNAMIC_MIXED_DYNAMIC_SAME_ID_REJECT_MAPPING_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_ONE_DYNAMIC_MIXED_DYNAMIC_SAME_ID_REJECT_MAPPING_CONTRACT_SELECTION.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.446|ONE_DYNAMIC_MIXED_DYNAMIC_SAME_ID_REJECT_MAPPING_BEHAVIOR|generated_mixed_static_id_exclusion_reject|generated_static_id_exclusion_assertions|mixed_dynamic_static_covered|generated_dynamic_request_static_id_exclusion_assertions|generated_response_unique_match_assertions' docs/AXI_IAL2_MANAGER_ONE_DYNAMIC_MIXED_DYNAMIC_SAME_ID_REJECT_MAPPING_BEHAVIOR.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1436-ial2-ppif-parser-cli.t t/1437-axi-ial2-manager-capacity-status-generator.t t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.446` maps selected one-dynamic mixed
dynamic/static `(dynamic-id-reuse reject)` policy to existing generated
static-ID exclusion, mixed request onehot0, response active/unique-match, and
completion-active response-demux assertions.

Covered reports use `implementation_status:
generated_mixed_static_id_exclusion_reject`, `enforcement:
generated_static_id_exclusion_assertions`, `assertion_enforcement:
runtime_assertion`, `response_demux_covered: true`,
`mixed_dynamic_static_covered: true`, `mixed_dynamic_static_request_policy:
onehot0_mixed_request`, `static_id_conflict_policy:
static_concrete_ids_reserved`, and `static_id_exclusion_policy:
dynamic_id_must_not_equal_static_concrete_id`.

The covered shapes are write `BID`, read single-beat `RID`, and read
burst-last `RID && RLAST` generated mixed response-demux families with exactly
one dynamic transaction plus one, two, or three pairwise-distinct concrete
static transactions. `.446` adds no generated HDL behavior and no new public
PPIF sample; tests insert the same-ID policy into existing samples in memory
and compare generated IAL1/IAL0 artifacts against the original samples.
`.446` selects `.447`, the next post-mapping selector.
