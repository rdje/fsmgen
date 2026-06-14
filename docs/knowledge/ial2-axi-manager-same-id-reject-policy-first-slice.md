---
id: ial2-axi-manager-same-id-reject-policy-first-slice
title: Same-ID reject policy parser/report/static validation shipped
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.92 ship?"
  - "how does FSMGen report same-ID reject policy?"
  - "what is the PPIF same-id-ordering reject policy behavior?"
  - "does explicit same-ID reject policy change generated HDL?"
  - "what is the next IAL2 frontier after same-ID reject policy?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, same-id, concrete-id, policy, ppif, report, task-tree]
evidence: docs/AXI_IAL2_MANAGER_SAME_ID_REJECT_POLICY_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_POST_SAME_ID_REJECT_POLICY_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_METADATA_FIRST_SLICE.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; ppif/axi_manager_capacity_status_same_id_reject_policy.ppif; ppif/axi_manager_capacity_status_same_id_issue_order_queue_policy.ppif; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.92|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.96|same_id_ordering_policy|same-id-ordering|concrete_id_reuse_policy|issue_order_queue|generated_queue_behavior|same-ID reject policy' docs/AXI_IAL2_MANAGER_SAME_ID_REJECT_POLICY_FIRST_SLICE.md docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_METADATA_FIRST_SLICE.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Adapter/IAL2/PPIF.pm t/1437-axi-ial2-manager-capacity-status-generator.t t/1436-ial2-ppif-parser-cli.t README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.92` shipped the explicit AXI same-ID
reuse reject policy first slice. At that slice boundary, PPIF accepted one optional
`(same-id-ordering ...)` clause under `manager-capacity-status`; each selected
`read` or `write` family must contain exactly one
`(concrete-id-reuse reject)` policy. Duplicate top-level clauses, duplicate
families, duplicate policy clauses, missing policy clauses, unsupported
families, and unsupported values such as `issue-order-queue` or `scoreboard`
fail closed.

Current behavior is wider: `.96` additionally accepts
`(concrete-id-reuse issue-order-queue)` as selected-not-generated metadata,
while `scoreboard` remains unsupported and duplicated concrete same-ID reuse
still fails closed.

Schedule JSON reports policy-only metadata under `same_id_ordering`:
`mode: concrete_id_reuse_policy`, `generated_behavior: false`, and
`concrete_id_reuse_policy.<family>.generated_queue_behavior: false`.
Generated `.isf`, `.fsm`, and SystemVerilog stay unchanged for valid
single-concrete-ID sources.

Omitted policy preserves the `.88` diagnostic requiring a selected policy or
per-ID issue-order queue. Explicit `reject` emits a policy-specific duplicate
concrete-ID diagnostic. Follow-up selector `.93` chose
`IAL2-FEATURE-COMPLETENESS-FRONTIER.94`, AXI same-ID issue-order queue policy
contract selection, before parser/report metadata or generated queue behavior.
