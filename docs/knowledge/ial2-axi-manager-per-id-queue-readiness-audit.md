---
id: ial2-axi-manager-per-id-queue-readiness-audit
title: Per-ID queue readiness selects same-ID reuse policy contract
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.90 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.91?"
  - "what comes after AXI per-ID issue-order queue readiness?"
  - "should AXI per-ID issue-order queues be implemented next?"
  - "why is same-ID reuse policy needed before per-ID queues?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, same-id, concrete-id, per-id-queues, policy, task-tree]
evidence: docs/AXI_IAL2_MANAGER_PER_ID_QUEUE_READINESS_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/AXI_IAL2_MANAGER_POST_CONCRETE_ID_STATIC_VALIDATION_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_CONCRETE_ID_SAME_ID_STATIC_VALIDATION_FIRST_SLICE.md; docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md; docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.90|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.91|PER_ID_QUEUE_READINESS_AUDIT|same-ID reuse policy contract|reject, queue, stall' docs/AXI_IAL2_MANAGER_PER_ID_QUEUE_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.90` audited AXI per-ID issue-order queue
readiness after concrete-ID same-ID static validation.

It selected `IAL2-FEATURE-COMPLETENESS-FRONTIER.91`: public AXI same-ID reuse
policy contract selection before parser/report metadata or generated queue
behavior.

Direct per-ID queue implementation is not next. The public `.ppif`
manager-capacity surface does not yet define whether same-ID reuse should be
rejected, queued, stalled, blocked, or accepted with scoreboard semantics.
Concrete-ID response demux cannot distinguish two same-ID transactions without
selected issue-order state.

The lower layers are not the immediate blocker: existing scalar storage,
guarded rules, pulses, assertions, bank metadata, and FIFO-like update
substrate are enough for a later bounded implementation once the public policy
contract is selected.
