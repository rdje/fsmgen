---
id: ial2-post-single-active-dynamic-same-id-reject-mapping-next-slice-selection
title: Post single-active dynamic same-ID reject selector chooses one-dynamic mixed audit
answers:
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.443 select?"
  - "what comes after single-active dynamic same-ID reject mapping?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.444?"
  - "why audit one-dynamic mixed dynamic same-ID reject mapping next?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_SINGLE_ACTIVE_DYNAMIC_SAME_ID_REJECT_MAPPING_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_SINGLE_ACTIVE_DYNAMIC_SAME_ID_REJECT_MAPPING_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_REJECT_ENFORCEMENT_MAPPING_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.443|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.444|POST_SINGLE_ACTIVE_DYNAMIC_SAME_ID_REJECT_MAPPING_NEXT_SLICE_SELECTION|one-dynamic mixed dynamic/static dynamic same-ID reject|mixed_dynamic_static_unique|static_id_conflict_policy|dynamic_request_not_static_id' docs/AXI_IAL2_MANAGER_POST_SINGLE_ACTIVE_DYNAMIC_SAME_ID_REJECT_MAPPING_NEXT_SLICE_SELECTION.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1437-axi-ial2-manager-capacity-status-generator.t docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.443` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.444`, readiness audit for one-dynamic
mixed dynamic/static dynamic same-ID reject mapping.

The selector changes no behavior. It chooses an audit because one-dynamic
mixed response-demux shapes already expose static-ID reservation/exclusion,
mixed request onehot0, response active/unique-match, and completion-active
assertion evidence, but they do not expose the `.438` multi-active dynamic
no-active-same-ID plus active-ID uniqueness assertion pair.

`.444` must decide whether that mixed static-ID exclusion evidence can support
a public generated reject report contract distinct from both `.438`
multi-active coverage and `.442` single-active coverage. Dynamic queues,
scoreboards, direct backend behavior, backend-language variants, VHDL, and new
generated HDL remain deferred.
