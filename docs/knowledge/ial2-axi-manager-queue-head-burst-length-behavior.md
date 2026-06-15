---
id: ial2-axi-manager-queue-head-burst-length-behavior
title: Queue-head last-beat read-data supports report-only raw-ARLEN burst-length capture
answers:
  - "does queue-head last-beat read-data support burst-length?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.117 ship?"
  - "which PPIF sample covers queue-head burst-length capture?"
  - "does queue-head burst-length support runtime validation?"
  - "what is generated for axi0_arlen in queue-head read-data?"
date: 2026-06-15
status: current
tags: [ial2, axi, manager, read-data, queue-head, burst-length, arlen]
evidence: docs/AXI_IAL2_MANAGER_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md; ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length.ppif && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.117|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.118|queue-head burst-length|axi0_arlen|generated_burst_length_capture|queue-head runtime burst-length' docs/AXI_IAL2_MANAGER_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.117` shipped report-only raw-`ARLEN`
burst-length capture for the bounded read burst-last concrete same-ID
queue-head last-beat read-data shape.

The public support-accounted sample is
`ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length.ppif`.
It combines the `.115` queue-head last-beat read-data shape with
`read_data.read.burst_length` metadata using `source arlen`, signal
`axi0_arlen` width 8, `encoding axlen-plus-one`, `capture request`,
`max-beats 16`, and `validation report-only`.

FSMGen emits generated `axi0_arlen` input, per-transaction raw-`ARLEN`
storage `axi0_r0_arlen_q` and `axi0_r1_arlen_q`, and request-guarded
capture rules `axi0_r0_burst_length_capture` and
`axi0_r1_burst_length_capture`. The last-beat `RDATA`/`RRESP` capture still
uses generated queue-head last-beat completion pulses.

The report keeps
`completion_validity: generated_queue_head_response_demux_last_beat_completion_pulse`
and sets `burst_length_generated_behavior: true`. Queue-head
`validation runtime-assertion`, queue-head beat-count/RLAST validation,
multi-beat queue-head read-data, deeper/multiple queue groups, mixed auto-ID,
direct backend, and VHDL remain deferred.
