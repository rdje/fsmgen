---
id: ial2-dynamic-read-same-id-issue-order-queue-recapture-readiness-audit
title: Dynamic read same-ID issue-order queue recapture readiness selected contract follow-up
answers:
  - "what follows dynamic read issue-order queue multi-beat output banks?"
  - "does dynamic issue-order queue recapture need new queue behavior?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.474 select?"
  - "why is queue recapture report/static alignment next?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, recapture, report, readiness]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_RECAPTURE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1436-ial2-ppif-parser-cli.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.474|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.475|DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_RECAPTURE_READINESS_AUDIT|dequeue_enqueue|same-cycle selected-dequeue-plus-enqueue|queue-owned recapture|report/static contract' docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_RECAPTURE_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1436-ial2-ppif-parser-cli.t
---

After `.473` shipped multi-beat output banks over generated dynamic read
same-ID `issue-order-queue` runtime-validation read-data, `.474` selected
`.475`, public report/static contract selection for queue-owned same-cycle
selected-dequeue-plus-enqueue recapture.

No new queue state-machine behavior is selected by `.474`. The generated
dynamic issue-order queue already emits `*_dequeue_enqueue_*` update rules.
`.475` later narrows the public interpretation: that literal rule list is not
a complete same-transaction recapture guarantee until the one-entry
identity-preserving ID-refresh case is audited.

The gap is public vocabulary: queue reports expose generated update rules, but
they do not expose the classic dynamic response-demux
`same_cycle_release_recapture_policy` / `release_recapture_*` fields because
queue-owned recapture is a compact slot update, not a busy/selected-ID
release-recapture rule.

`.475` pinned the interim report contract and selected `.476`: keep
`generated_update_rules` as literal emitted-rule evidence, keep classic
`same_cycle_release_recapture_policy` / `release_recapture_*` fields exclusive
to response-demux capture state, and audit identity-preserving one-entry ID
refresh before any positive queue recapture report field is added.
