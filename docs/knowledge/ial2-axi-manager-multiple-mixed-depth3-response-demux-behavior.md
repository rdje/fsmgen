---
id: ial2-axi-manager-multiple-mixed-depth3-response-demux-behavior
title: Multiple/mixed depth-3 queue-head response-demux is generated
answers:
  - "are multiple depth-3 queue-head response-demux groups generated?"
  - "are mixed depth-3 and depth-2 queue-head response-demux groups generated?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.174 ship?"
  - "what does ppif/axi_manager_capacity_status_read_single_beat_multi_depth3_same_id_queue_head_response_demux.ppif cover?"
  - "what support-accounting entries cover multiple or mixed depth-3 queue-head response-demux?"
date: 2026-06-18
status: current
tags: [ial2, axi, manager, read, write, response-demux, queue-head, depth-3, behavior]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md; ppif/axi_manager_capacity_status_read_single_beat_multi_depth3_same_id_queue_head_response_demux.ppif; ppif/axi_manager_capacity_status_read_single_beat_mixed_depth3_depth2_same_id_queue_head_response_demux.ppif; ppif/axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_response_demux.ppif; ppif/axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_response_demux.ppif; ppif/axi_manager_capacity_status_write_multi_depth3_same_id_queue_head_response_demux.ppif; ppif/axi_manager_capacity_status_write_mixed_depth3_depth2_same_id_queue_head_response_demux.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; t/248-regression-corpus-accounting.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; docs/book/src/14-feature-backlog.md
reverify: ./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_single_beat_multi_depth3_same_id_queue_head_response_demux.ppif
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.174` shipped generated multiple or mixed
depth-3 concrete same-ID queue-head response-demux for response-demux-only
read single-beat, read burst-last, and write families.

The public samples cover two-depth-3 and mixed depth-3/depth-2 queue sets for
each family. The generated report boundaries remain
`generated_read_single_beat_queue_head_demux`,
`generated_read_burst_last_queue_head_demux`, and
`generated_write_bid_queue_head_demux`.

Two-depth-3 samples generate two independent depth-3 queues, six transaction
completion outputs, six response-demux rules, and 16 response-demux
assertions. Mixed samples generate one depth-3 queue plus one depth-2 queue,
five completion outputs, five response-demux rules, and 11 response-demux
assertions.

Each sample is support-accounted through its matching `intent.ppif_*` entry.
The slice intentionally leaves read-data over multiple/mixed depth-3 groups,
burst-length, runtime-validation, multi-beat payload, mixed auto-ID,
group-local enqueue widening, packed outputs, direct backend,
verification-output generation, VHDL, and backend-language variants behind
future exact owners.
