---
id: ial2-axi-manager-multiple-mixed-depth3-read-data-behavior
title: Multiple/mixed depth-3 queue-head read-data is generated for read single-beat
answers:
  - "are multiple depth-3 queue-head read-data groups generated?"
  - "are mixed depth-3 and depth-2 queue-head read-data groups generated?"
  - "is read-data over multiple or mixed depth-3 queue-head groups generated?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.177 ship?"
  - "what support-accounting entries cover multiple or mixed depth-3 queue-head read-data?"
date: 2026-06-18
status: current
tags: [ial2, axi, manager, read-data, queue-head, depth-3, behavior]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_READ_DATA_BEHAVIOR.md; ppif/axi_manager_capacity_status_read_single_beat_multi_depth3_same_id_queue_head_read_data.ppif; ppif/axi_manager_capacity_status_read_single_beat_mixed_depth3_depth2_same_id_queue_head_read_data.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; t/248-regression-corpus-accounting.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: ./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_single_beat_multi_depth3_same_id_queue_head_read_data.ppif
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.177` shipped generated read single-beat
scalar `RDATA`/`RRESP` capture over generated multiple or mixed depth-3
concrete same-ID queue-head response-demux groups.

The public samples cover two-depth-3 groups (`r0/r1/r2` and `r3/r4/r5`) and
mixed depth-3/depth-2 groups (`r0/r1/r2` and `r3/r4`). Each transaction gets
scalar data/status outputs and a read-data capture rule guarded by the
generated queue-head completion pulse. The read-data report keeps
`generated_queue_head_response_demux_completion_pulse` completion validity and
residue `rlast_completion`, `bursts`, and `multi_beat_read_data_reassembly`.

The support-accounting entries are:

```text
intent.ppif_axi_manager_capacity_status_read_single_beat_multi_depth3_same_id_queue_head_read_data
intent.ppif_axi_manager_capacity_status_read_single_beat_mixed_depth3_depth2_same_id_queue_head_read_data
```

Read burst-last read-data over multiple/mixed depth-3 groups, burst-length,
runtime-validation, multi-beat payload, write-family read-data, mixed auto-ID,
direct backend, VHDL, and backend-language variants remain future owned work.
