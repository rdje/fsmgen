---
id: ial2-one-dynamic-mixed-dynamic-same-id-reject-mapping-contract-selection
title: One-dynamic mixed dynamic same-ID reject contract selects direct implementation
answers:
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.445 select?"
  - "what report fields should one-dynamic mixed dynamic-id-reuse reject use?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.446?"
  - "which one-dynamic mixed shapes are selected for dynamic same-ID reject mapping?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, response-demux, contract]
evidence: docs/AXI_IAL2_MANAGER_ONE_DYNAMIC_MIXED_DYNAMIC_SAME_ID_REJECT_MAPPING_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_ONE_DYNAMIC_MIXED_DYNAMIC_SAME_ID_REJECT_MAPPING_READINESS_AUDIT.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.445|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.446|ONE_DYNAMIC_MIXED_DYNAMIC_SAME_ID_REJECT_MAPPING_CONTRACT_SELECTION|generated_mixed_static_id_exclusion_reject|generated_static_id_exclusion_assertions|mixed_dynamic_static_covered|generated_dynamic_request_static_id_exclusion_assertions' docs/AXI_IAL2_MANAGER_ONE_DYNAMIC_MIXED_DYNAMIC_SAME_ID_REJECT_MAPPING_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.445` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.446`, direct implementation of
one-dynamic mixed dynamic/static dynamic same-ID reject mapping.

The selected report contract uses `implementation_status:
generated_mixed_static_id_exclusion_reject`, `enforcement:
generated_static_id_exclusion_assertions`, `mixed_dynamic_static_covered:
true`, `mixed_dynamic_static_request_policy: onehot0_mixed_request`,
`static_id_conflict_policy: static_concrete_ids_reserved`, and
`static_id_exclusion_policy: dynamic_id_must_not_equal_static_concrete_id`.

The covered shapes are write `BID`, read single-beat `RID`, and read
burst-last `RID && RLAST` with exactly one dynamic transaction plus one, two,
or three pairwise-distinct concrete static transactions. The contract
deliberately does not reuse `.438` multi-active assertion fields or `.442`
single-active fields.
