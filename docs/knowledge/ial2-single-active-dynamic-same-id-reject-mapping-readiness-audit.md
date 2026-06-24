---
id: ial2-single-active-dynamic-same-id-reject-mapping-readiness-audit
title: Single-active dynamic same-ID reject mapping is ready for contract selection
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.440 select?"
  - "can single-active dynamic same-ID reject mapping use existing assertions?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.441?"
  - "why is single-active dynamic reject mapping not the same as the .438 multi-active mapping?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, readiness]
evidence: docs/AXI_IAL2_MANAGER_SINGLE_ACTIVE_DYNAMIC_SAME_ID_REJECT_MAPPING_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_DYNAMIC_SAME_ID_REJECT_MAPPING_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_REJECT_ENFORCEMENT_MAPPING_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_SAME_CYCLE_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_CYCLE_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_RECAPTURE_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.440|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.441|SINGLE_ACTIVE_DYNAMIC_SAME_ID_REJECT_MAPPING_READINESS_AUDIT|dynamic_request_idle_or_releasing|single_active_dynamic_write|single_active_dynamic_read|generated multi-active dynamic response-demux no-active-same-ID assertions' docs/AXI_IAL2_MANAGER_SINGLE_ACTIVE_DYNAMIC_SAME_ID_REJECT_MAPPING_READINESS_AUDIT.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.440` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.441`, public contract selection for
single-active dynamic same-ID reject mapping.

The single-active write, read single-beat, and read burst-last response-demux
families already generate `*_dynamic_request_idle_or_releasing`,
active-match, and completion-active assertions. Those assertions are strong
enough to justify a contract discussion because one dynamic transaction cannot
have a sibling active same-ID conflict.

The mapping still needs a separate contract because the `.438` multi-active
report fields credit `*_dynamic_request_no_active_same_id` and
`*_dynamic_active_id_unique` assertions, which single-active shapes do not
generate.
