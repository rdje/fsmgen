---
id: ial2-post-mixed-auto-id-queue-head-multi-beat-next-slice-selection
title: Post mixed multi-beat selector chooses group-local enqueue audit
answers:
  - "what comes after mixed auto-id queue-head multi-beat read-data?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.208 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.209?"
  - "why is group-local enqueue widening next after mixed multi-beat?"
date: 2026-06-21
status: current
tags: [ial2, axi, manager, same-id, queue-head, group-local, task-tree]
evidence: docs/AXI_IAL2_MANAGER_POST_MIXED_AUTO_ID_QUEUE_HEAD_MULTI_BEAT_NEXT_SLICE_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.208|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.209|POST_MIXED_AUTO_ID_QUEUE_HEAD_MULTI_BEAT_NEXT_SLICE_SELECTION|group-local simultaneous enqueue|family-wide request onehot|axi0_read_issue_order_queue_request_onehot0|axi0_write_issue_order_queue_request_onehot0' docs/AXI_IAL2_MANAGER_POST_MIXED_AUTO_ID_QUEUE_HEAD_MULTI_BEAT_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.208` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.209`, readiness audit for group-local
simultaneous enqueue widening across generated concrete same-ID queue-head
families.

The selector follows `.207`, which shipped generated mixed multi-beat
output-bank behavior over the same-family mixed auto-ID plus depth-2 concrete
same-ID queue-head runtime-validation shape. Representative generated
queue-head samples still report one family-wide request mutual-exclusion
assertion such as `axi0_read_issue_order_queue_request_onehot0` or
`axi0_write_issue_order_queue_request_onehot0`, even when the family has
multiple concrete-ID queue groups.

Group-local enqueue widening is selected before packed burst outputs,
alternate payload assembly, direct backend, verification-output generation,
VHDL, or broader queue variants because it is the remaining local
queue-semantics boundary. `.209` is audit-only: it must decide whether the
family-wide request onehot can become group-local, whether the direction-level
capacity counter needs a prerequisite, and whether queue transition generation
can handle distinct concrete-ID group enqueues in the same cycle.
