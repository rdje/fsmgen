---
id: ial2-one-dynamic-mixed-dynamic-same-id-reject-mapping-readiness-audit
title: One-dynamic mixed dynamic same-ID reject mapping is ready for contract selection
answers:
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.444 select?"
  - "is one-dynamic mixed dynamic-id-reuse reject ready to implement?"
  - "why does one-dynamic mixed dynamic same-ID reject need a separate contract?"
  - "what evidence exists for one-dynamic mixed dynamic same-ID reject mapping?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, response-demux, audit]
evidence: docs/AXI_IAL2_MANAGER_ONE_DYNAMIC_MIXED_DYNAMIC_SAME_ID_REJECT_MAPPING_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_SINGLE_ACTIVE_DYNAMIC_SAME_ID_REJECT_MAPPING_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_SINGLE_ACTIVE_DYNAMIC_SAME_ID_REJECT_MAPPING_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_REJECT_ENFORCEMENT_MAPPING_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.444|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.445|ONE_DYNAMIC_MIXED_DYNAMIC_SAME_ID_REJECT_MAPPING_READINESS_AUDIT|mixed_dynamic_static_unique|multi_mixed_dynamic_static_unique|static_id_conflict_policy|dynamic_request_not_static_id|dynamic_active_not_static_id|mixed_dynamic_static_response_active_match' docs/AXI_IAL2_MANAGER_ONE_DYNAMIC_MIXED_DYNAMIC_SAME_ID_REJECT_MAPPING_READINESS_AUDIT.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1437-axi-ial2-manager-capacity-status-generator.t docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.444` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.445`, public report contract selection for
one-dynamic mixed dynamic/static dynamic same-ID reject mapping.

The audit changes no behavior. It found the generated evidence ready for a
contract selection because one-dynamic mixed response-demux reports already
expose static concrete ID reservation/exclusion, dynamic request-not-static-ID
and active-not-static-ID assertions, mixed request onehot0, response
active/unique-match assertions, and completion-active assertions.

Direct implementation is deferred because this is a third evidence model:
it should not reuse `.438` multi-active no-active-same-ID fields or `.442`
single-active idle-or-releasing fields without a public report contract first.
Dynamic queues, scoreboards, direct backend behavior, backend-language
variants, VHDL, and new generated HDL remain deferred.
