---
id: ial2-dynamic-read-same-id-issue-order-queue-read-data-multi-beat-readiness-audit
title: Dynamic read same-ID issue-order queue read-data multi-beat audit selects implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.472 select?"
  - "is multi-beat output-bank capture ready for dynamic read issue-order queue read-data?"
  - "what sample should cover dynamic read issue-order queue read-data multi-beat output banks?"
  - "does dynamic read issue-order queue multi-beat read-data need a new public contract?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, read-data, multi-beat, output-bank, arlen, rlast, runtime-assertion, readiness]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_MULTI_BEAT_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.472|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.473|DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_READINESS_AUDIT|dynamic_read_burst_last_same_id_issue_order_queue_read_data_multi_beat|generated_dynamic_issue_order_queue_demux_last_beat|multi-beat output-bank|per_beat_output_bank' docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_READINESS_AUDIT.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.472` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.473`, direct bounded implementation of
multi-beat output banks over generated dynamic read same-ID
`issue-order-queue` runtime-validation read-data.

No new public contract-selection leaf is required because existing
`read-data.read` multi-beat syntax already defines per-beat status,
worst-observed aggregation, multi-beat-by-RID interleaving,
runtime-assertion `burst-length`, and complete per-transaction output-bank
bindings. A guarded temporary queue multi-beat candidate failed closed only at
the local dynamic issue-order queue read-data coverage gate.

The selected public sample is
`ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data_multi_beat.ppif`.
`.473` should keep queue recapture widening, broader queues, mixed
dynamic/static queues, scoreboards, direct backend behavior,
backend-language variants, and VHDL as future exact owners.
