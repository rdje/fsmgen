---
id: ial2-axi-manager-queue-head-read-data-behavior
title: AXI manager queue-head read-data behavior covers generated read single-beat queue-head demux
layer: B
date: 2026-06-15
owner: IAL2-FEATURE-COMPLETENESS-FRONTIER.113
evidence: docs/AXI_IAL2_MANAGER_QUEUE_HEAD_READ_DATA_BEHAVIOR_FIRST_SLICE.md; ppif/axi_manager_capacity_status_read_single_beat_same_id_queue_head_read_data.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; perl/FSM/Support/RegressionCorpus.pm; docs/REGRESSION_CORPUS.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_single_beat_same_id_queue_head_read_data.ppif && env -u PERL5LIB ./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_queue_head_read_data_reverify.sv ppif/axi_manager_capacity_status_read_single_beat_same_id_queue_head_read_data.ppif && env -u PERL5LIB prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t t/1436-ial2-ppif-parser-cli.t
questions:
  - "does AXI manager read-data support generated queue-head response demux?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.113 ship?"
  - "what is generated_queue_head_response_demux_completion_pulse?"
  - "which PPIF sample covers queue-head read-data?"
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.113` shipped generated single-beat
`RDATA`/`RRESP` capture when `read-data` consumes the generated read
single-beat concrete same-ID queue-head response demux. The public sample is
`ppif/axi_manager_capacity_status_read_single_beat_same_id_queue_head_read_data.ppif`.

The supported boundary is exactly one read `response-scope single-beat`
queue-head demux, one duplicate concrete read-ID group, two read transactions,
computed queue depth 2, `read-data.read.capture-scope single-beat`,
`completion-source response-demux`, and `interleaving single-beat-by-rid`.
Read-data coverage is derived from the generated queue-head transaction group
and `generated_completion_signals`, not from `auto_transactions`.

The report marks `read_data.read.completion_validity` as
`generated_queue_head_response_demux_completion_pulse` for this queue-head
path. The existing auto-ID read-data path keeps
`generated_read_response_demux_completion_pulse`.

Read burst-last queue-head read-data, last-beat or multi-beat queue-head
read-data, deeper or multiple groups, mixed same-family auto-ID plus concrete
queue-head demux, direct backend lowering, and VHDL remain deferred.
