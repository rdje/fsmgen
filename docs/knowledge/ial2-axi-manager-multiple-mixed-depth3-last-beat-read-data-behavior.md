---
id: ial2-axi-manager-multiple-mixed-depth3-last-beat-read-data-behavior
title: Multiple/mixed depth-3 burst-last queue-head read-data is generated without burst_length
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.180 ship?"
  - "does AXI manager read-data support burst-last multiple depth-3 queue-head groups?"
  - "does AXI manager read-data support mixed depth-3/depth-2 burst-last queue-head groups?"
  - "what PPIF samples cover multiple/mixed depth-3 burst-last read-data?"
  - "is burst_length required for multiple/mixed depth-3 burst-last read-data?"
date: 2026-06-18
status: current
tags: [ial2, axi, manager, read-data, burst-last, queue-head, depth-3, behavior]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_LAST_BEAT_READ_DATA_BEHAVIOR.md; ppif/axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_read_data.ppif; ppif/axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_read_data.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; t/248-regression-corpus-accounting.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: env -u PERL5LIB ./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_read_data.ppif && env -u PERL5LIB ./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_read_data.ppif
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.180` shipped generated read burst-last
scalar last-beat `RDATA`/`RRESP` over generated concrete same-ID queue-head
response-demux groups where every duplicate concrete `RID` group has computed
depth `2` or `3`, at least one group has depth `3`, and no `burst_length`
metadata is present.

The public samples are:

- `ppif/axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_read_data.ppif`
- `ppif/axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_read_data.ppif`

They are support-accounted as:

- `intent.ppif_axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_read_data`
- `intent.ppif_axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_read_data`

The support boundary is read family only, `response-scope burst-last`, one-bit
`RLAST`, `capture-scope last-beat`, `status-policy last-beat`, `interleaving
last-beat-by-rid`, generated read burst-last queue-head response-demux
completion, and scalar last-beat data/status outputs for every covered
transaction.

The following remain deferred for separate owners: burst-length metadata,
runtime beat-count/`RLAST` validation, multi-beat payload behavior over these
multiple/mixed depth-3 groups, write-family read-data, same-family mixed
auto-ID plus concrete queue-head demux, group-local enqueue widening, packed
burst-vector outputs, alternate full burst assembly, verification-output
generation, direct backend lowering, VHDL, and backend-language variants.
