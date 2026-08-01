---
id: ial2-dynamic-read-burst-last-depth3-same-id-issue-order-queue-read-data-multi-beat-behavior
title: Depth-3 dynamic RLAST queue read-data supports multi-beat output banks
answers:
  - "does depth-3 dynamic RLAST queue read-data support multi-beat output banks?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.500 ship?"
  - "which PPIF sample covers depth-3 dynamic RLAST queue read-data multi-beat output banks?"
  - "does depth-3 dynamic RLAST queue multi-beat depend on sv2v?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, rlast, read-data, burst-length, arlen, runtime-validation, multi-beat, output-bank, behavior]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_BEHAVIOR.md; ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_multi_beat.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t; docs/REGRESSION_CORPUS.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: >-
  rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.500|axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_multi_beat|bounded_multi_beat_read_data_contract|axi0_r2_beat_rdata_15|axi0_r2_beat_valid|axi0_r2_read_beats|sv2v' docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_BEHAVIOR.md ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_multi_beat.ppif perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm t/1436-ial2-ppif-parser-cli.t t/1437-axi-ial2-manager-capacity-status-generator.t t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t t/248-regression-corpus-accounting.t docs/REGRESSION_CORPUS.md
  docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`.500` ships multi-beat read-data output banks over the generated
all-dynamic read burst-last `RID && RLAST` depth-3 same-ID
`issue-order-queue` runtime-validation read-data behavior from `.497`.

The public sample is
`ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_multi_beat.ppif`.
It covers exactly `r0`, `r1`, and `r2`; queue depth 3; one-bit `axi0_rlast`;
`generated_dynamic_issue_order_queue_demux_last_beat`; and `read-data.read`
multi-beat syntax with `axi0_arlen` width 8, `axlen-plus-one`, request
capture, max-beats 16, runtime-assertion validation, per-transaction
data/status output prefixes, valid-mask outputs, length outputs, and
worst-observed scalar `RRESP` aggregation.

For the default `max-beats 16` sample, FSMGen generates 48 `RDATA` lane
outputs, 48 `RRESP` lane outputs, three valid-mask outputs, three length
outputs, three scalar aggregate outputs, 48 lane-capture rules, three
aggregate update rules, and the `.497` raw-`ARLEN` runtime-validation state
and assertions. It remains FSMGen-owned generation/lowering: external
converters such as `sv2v`, backend variants, arbitrary cardinality, mixed
dynamic/static queues, scoreboards, verification-code generation, and VHDL
remain deferred.
