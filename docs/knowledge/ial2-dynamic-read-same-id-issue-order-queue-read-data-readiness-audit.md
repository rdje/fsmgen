---
id: ial2-dynamic-read-same-id-issue-order-queue-read-data-readiness-audit
title: Dynamic read same-ID issue-order queue read-data audit selects paired contract
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.465 select?"
  - "is read-data over generated dynamic read issue-order queues ready?"
  - "what completion validity should dynamic read issue-order queue read-data use?"
  - "why does dynamic read queue read-data need contract selection?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, read-data, readiness]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SINGLE_BEAT_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.465|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.466|DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_READINESS_AUDIT|generated_dynamic_read_issue_order_queue_response_demux_completion_pulse|generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse|generated_dynamic_issue_order_queue_demux' docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_READINESS_AUDIT.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.465` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.466`, public contract selection for paired
bounded scalar read-data routing over generated dynamic read same-ID
`issue-order-queue` completions.

The audit changes no behavior. It finds the downstream read-data artifact path
ready once coverage accepts queue completion sources, but it keeps one
contract-selection leaf before implementation because the public queue-specific
completion-validity names, paired single-beat plus last-beat scope, diagnostics,
sample identities, report keys, residue, validation, and rollback boundary
must be pinned before parser/generator/sample/test/support changes.

`.466` should pin
`generated_dynamic_read_issue_order_queue_response_demux_completion_pulse` and
`generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse`
for the paired scalar queue read-data contract. Raw `ARLEN`, runtime
validation, multi-beat output banks, queue recapture widening, broader queue
cardinality, mixed dynamic/static queues, scoreboards, direct backend behavior,
backend-language variants, and VHDL remain future exact owners until selected.
