---
id: ial2-counted-same-id-capacity-substrate
title: Counted same-ID capacity substrate is shipped for multi-group queue-head families
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.211 ship?"
  - "does AXI manager same-ID queue-head capacity count multiple request groups?"
  - "what is counted_same_id_selected_requests?"
  - "what is the over-capacity policy for counted same-ID requests?"
  - "did .211 enable group-local simultaneous enqueue?"
date: 2026-06-22
status: current
tags: [ial2, axi, manager, same-id, counted-capacity, queue-head]
evidence: docs/AXI_IAL2_MANAGER_COUNTED_SAME_ID_CAPACITY_SUBSTRATE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_COUNTED_ADMITTED_REQUEST_GUARD_READINESS_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.211|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.214|counted_same_id_selected_requests|counted_submit|reject_current_request_set|request_count_expression|maximum_request_count|family-wide request onehot|group-local request assertions' docs/AXI_IAL2_MANAGER_COUNTED_SAME_ID_CAPACITY_SUBSTRATE_BEHAVIOR.md docs/AXI_IAL2_MANAGER_COUNTED_ADMITTED_REQUEST_GUARD_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1437-axi-ial2-manager-capacity-status-generator.t t/1436-ial2-ppif-parser-cli.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.211` shipped counted same-ID
selected-request capacity/status substrate for generated queue-head families
with multiple concrete-ID groups.

The public read/write multi-group queue-head response-demux reports now expose
`request_accounting.mode: counted_same_id_selected_requests`,
`counted_request_events`, `counted_request_terms`, `counted_request_groups`,
`selected_same_id_request_events`, `request_count_expression`,
`maximum_request_count`, `capacity_owner`, Boolean completion accounting, and
`over_capacity_policy: reject_current_request_set`. The affected
`generated_scheduler_or_status_rules` capacity matrix reports
`accounting_mode: counted_submit`.

The substrate does not enable group-local simultaneous enqueue acceptance.
The existing family-wide same-ID request onehot assertions remain in place,
and legal public behavior stays one request per direction per cycle. `.213`
selected `.214`, which is the next implementation owner for aligning
admitted-request pulse guards with counted request-set capacity and narrowing
request assertions to concrete-ID groups only for counted multi-group
directions.
