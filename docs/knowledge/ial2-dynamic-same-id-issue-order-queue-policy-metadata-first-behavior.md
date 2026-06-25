---
id: ial2-dynamic-same-id-issue-order-queue-policy-metadata-first-behavior
title: Dynamic same-ID issue-order queue policy is metadata-first
answers:
  - "is dynamic-id-reuse issue-order-queue supported?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.450 ship?"
  - "which PPIF sample covers dynamic same-ID issue-order queue metadata?"
  - "does dynamic issue-order queue metadata generate queue behavior?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, ppif]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_POLICY_METADATA_FIRST_BEHAVIOR.md; ppif/axi_manager_capacity_status_dynamic_same_id_issue_order_queue_policy.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_same_id_issue_order_queue_policy.ppif
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.450` ships metadata-first parser/report
support for `dynamic-id-reuse issue-order-queue`.

The public PPIF sample is:

```text
ppif/axi_manager_capacity_status_dynamic_same_id_issue_order_queue_policy.ppif
```

The report uses `same_id_ordering.mode: dynamic_id_reuse_policy`,
`dynamic_id_reuse_policy.read.policy: issue_order_queue`,
`implementation_status: selected_not_generated`, `enforcement:
not_generated`, `accepted_same_id_reuse: false`,
`request_conflict_policy:
dynamic_issue_order_queue_selected_not_generated`,
`generated_queue_behavior: false`, and `generated_scoreboard_behavior:
false`. Residue includes `dynamic_id_same_id_ordering` and
`dynamic_per_id_issue_order_queues`.

Dynamic issue-order queue metadata does not generate queue state, queue-head
demux, accepted same-ID reuse, scoreboard behavior, HDL, VHDL, or direct
backend behavior.
