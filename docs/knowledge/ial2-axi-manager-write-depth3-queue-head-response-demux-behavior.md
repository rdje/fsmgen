---
id: ial2-axi-manager-write-depth3-queue-head-response-demux-behavior
title: Write depth-3 queue-head response-demux is generated for one BID group
answers:
  - "is write depth-3 queue-head response-demux generated?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.171 ship?"
  - "what does ppif/axi_manager_capacity_status_write_depth3_same_id_queue_head_response_demux.ppif cover?"
  - "what support-accounting entry covers write depth-3 queue-head response-demux?"
date: 2026-06-17
status: current
tags: [ial2, axi, manager, write, response-demux, queue-head, depth-3, behavior]
evidence: docs/AXI_IAL2_MANAGER_WRITE_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md; ppif/axi_manager_capacity_status_write_depth3_same_id_queue_head_response_demux.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; t/248-regression-corpus-accounting.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; docs/book/src/14-feature-backlog.md
reverify: ./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_write_depth3_same_id_queue_head_response_demux.ppif
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.171` shipped generated write-family
depth-3 concrete same-ID queue-head response-demux for exactly one write
group: `w0`, `w1`, and `w2` share concrete `BID` `3` with queue depth `3`.

The public sample is
`ppif/axi_manager_capacity_status_write_depth3_same_id_queue_head_response_demux.ppif`.
The generated boundary is `generated_write_bid_queue_head_demux`. Schedule
JSON reports three generated write completion outputs, three write
response-demux rules, four write response-demux assertions, nine queue slot
storage signals, 54 queue update rules, and 14 queue assertions.

Strict check JSON and semantic JSON support-account the sample as
`intent.ppif_axi_manager_capacity_status_write_depth3_same_id_queue_head_response_demux`
with coverage bucket
`ial2_ppif_manager_capacity_status_write_depth3_same_id_queue_head_response_demux_pipeline_cli`.

The slice intentionally leaves read-data, burst-length, runtime-validation,
multi-beat payload, read response-demux, `RLAST`, multiple or mixed depth-3
groups, mixed auto-ID, group-local enqueue widening, packed outputs, direct
backend, verification-output generation, VHDL, and backend-language variants
behind future exact owners.
