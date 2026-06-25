---
id: ial2-dynamic-read-burst-last-depth3-same-id-issue-order-queue-read-data-behavior
title: Depth-3 dynamic read RLAST queue scalar read-data behavior
answers:
  - "does FSMGen support scalar read-data over depth-3 dynamic read RLAST issue-order queues?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.491 ship?"
  - "which PPIF sample covers depth-3 dynamic RLAST queue read-data?"
  - "does depth-3 dynamic RLAST queue read-data depend on sv2v?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, rlast, read-data, behavior]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BEHAVIOR.md; ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.491|axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data|generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse|read_rid_rlast_three_dynamic_transactions|sv2v' docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BEHAVIOR.md ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data.ppif perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`.491` ships scalar last-beat read-data over the generated all-dynamic read
burst-last `RID && RLAST` depth-3 same-ID `issue-order-queue`. The public
sample is
`ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data.ppif`.

The behavior covers exactly `r0`, `r1`, and `r2`; queue depth 3; one-bit
`axi0_rlast`; `generated_dynamic_issue_order_queue_demux_last_beat`; and the
existing `read-data.read` last-beat syntax. It captures `axi0_rdata` and
`axi0_rresp` into `axi0_r*_last_rdata` and `axi0_r*_last_rresp` under each
generated completion pulse. Raw `ARLEN`, runtime validation, multi-beat
output banks, mixed dynamic/static queues, arbitrary cardinality, direct
backend behavior, backend-language variants, external converters such as
`sv2v`, and VHDL remain deferred. FSMGen-owned generation/lowering remains
the default.
