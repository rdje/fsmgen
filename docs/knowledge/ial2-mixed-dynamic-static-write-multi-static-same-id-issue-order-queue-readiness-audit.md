---
id: ial2-mixed-dynamic-static-write-multi-static-same-id-issue-order-queue-readiness-audit
title: Mixed dynamic/static write BID multi-static issue-order queue is ready for direct bounded implementation
answers:
  - "is one-dynamic plus two-static mixed write BID issue-order queue ready?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.523 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.524?"
  - "where does the mixed write BID multi-static issue-order queue fail today?"
date: 2026-06-26
status: current
tags: [ial2, axi, mixed-dynamic-static, issue-order-queue, write-bid, readiness]
evidence: docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_MULTI_STATIC_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; ppif/axi_manager_capacity_status_write_mixed_dynamic_static_same_id_issue_order_queue.ppif; ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static.ppif; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.523|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.524|MIXED_DYNAMIC_STATIC_WRITE_MULTI_STATIC_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT|one-dynamic plus two-concrete-static mixed dynamic/static write BID same-ID issue-order queue|requires exactly two or three all-dynamic write transactions, or exactly one dynamic plus one concrete static write transaction' docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_MULTI_STATIC_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.523` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.524`, direct bounded implementation of
one-dynamic plus two-concrete-static mixed dynamic/static write `BID` same-ID
`issue-order-queue` behavior.

The current candidate fails closed at the local mixed write issue-order queue
planner diagnostic: generated dynamic-id-reuse issue-order queues currently
accept all-dynamic two/three-write queues, or mixed one-dynamic plus one-static
write queues, but not the selected one-dynamic plus two-static write queue.
The shared lower queue transition, assignment, assertion, and report helpers
are already transaction-list driven enough for a bounded direct implementation
after the planner/materializer/report/test surfaces are widened.

`.524` should add the public multi-static mixed write queue sample, support
accounting, focused parser/generator tests, and docs/book sync. It must not
claim read queue widening, read-data, raw-`ARLEN`, runtime validation,
multi-beat output banks, scoreboards, arbitrary cardinality, backend behavior,
backend-language variants, external converter dependencies, or VHDL.
