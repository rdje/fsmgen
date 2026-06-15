---
id: ial2-axi-manager-queue-head-last-beat-read-data-behavior
title: AXI manager queue-head last-beat read-data behavior covers generated read burst-last queue-head demux
layer: B
date: 2026-06-15
owner: IAL2-FEATURE-COMPLETENESS-FRONTIER.115
evidence: docs/AXI_IAL2_MANAGER_QUEUE_HEAD_LAST_BEAT_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION.md; ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_read_data.ppif; ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; perl/FSM/Support/RegressionCorpus.pm; docs/REGRESSION_CORPUS.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_read_data.ppif && env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length.ppif && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.116|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.117|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.118|queue-head burst-length|raw-ARLEN|generated_queue_head_response_demux_last_beat_completion_pulse' docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION.md docs/AXI_IAL2_MANAGER_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
answers:
  - "does AXI manager read-data support generated burst-last queue-head response demux?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.115 ship?"
  - "what is generated_queue_head_response_demux_last_beat_completion_pulse?"
  - "which PPIF sample covers queue-head last-beat read-data?"
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.115` shipped generated last-beat
`RDATA`/`RRESP` capture when `read-data` consumes the generated read
burst-last concrete same-ID queue-head response demux. The public sample is
`ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_read_data.ppif`.

The supported boundary is exactly one read `response-scope burst-last`
queue-head demux, one duplicate concrete read-ID group, two read transactions,
computed queue depth 2, `read-data.read.capture-scope last-beat`,
`completion-source response-demux`, `status-policy last-beat`, and
`interleaving last-beat-by-rid`. Read-data coverage is derived from the
generated queue-head transaction group and generated completion signals, not
from `auto_transactions`.

The report marks `read_data.read.completion_validity` as
`generated_queue_head_response_demux_last_beat_completion_pulse` for this
queue-head last-beat path. Existing auto-ID last-beat read-data keeps
`generated_read_response_demux_last_beat_completion_pulse`, and existing
queue-head single-beat read-data keeps
`generated_queue_head_response_demux_completion_pulse`.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.116` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.117`, generated raw-`ARLEN`
burst-length capture for this bounded queue-head last-beat shape.
`IAL2-FEATURE-COMPLETENESS-FRONTIER.117` shipped that report-only follow-up
for
`ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length.ppif`.
Multi-beat queue-head read-data, queue-head runtime beat-count/RLAST
validation, deeper or multiple groups, mixed same-family auto-ID plus
concrete queue-head demux, direct backend lowering, and VHDL remain deferred.
