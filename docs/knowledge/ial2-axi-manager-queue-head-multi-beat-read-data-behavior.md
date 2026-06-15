---
id: ial2-axi-manager-queue-head-multi-beat-read-data-behavior
title: Queue-head burst-last read-data supports generated multi-beat output banks
answers:
  - "does queue-head read-data support multi-beat output banks?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.121 ship?"
  - "which PPIF sample covers queue-head multi-beat read-data?"
  - "what is the queue-head multi-beat read-data completion validity?"
  - "does queue-head multi-beat read-data clear read_data residue?"
date: 2026-06-15
status: current
tags: [ial2, axi, manager, read-data, queue-head, multi-beat, output-bank, rdata, rresp]
evidence: docs/AXI_IAL2_MANAGER_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR.md; ppif/axi_manager_capacity_status_read_multi_beat_same_id_queue_head_read_data.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_multi_beat_same_id_queue_head_read_data.ppif && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.121|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.122|queue-head multi-beat|read_multi_beat_same_id_queue_head_read_data|generated_queue_head_response_demux_last_beat_completion_pulse|per_beat_output_bank|read_data\\.residue: \\[\\]|response_demux\\.residue: \\[\\]' docs/AXI_IAL2_MANAGER_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.121` ships generated multi-beat
read-data output-bank behavior for the bounded read burst-last concrete
same-ID queue-head demux shape.

The public support-accounted sample is
`ppif/axi_manager_capacity_status_read_multi_beat_same_id_queue_head_read_data.ppif`.
It combines generated read burst-last queue-head response demux with
`read_data.read.capture_scope: multi_beat`, ARLEN runtime validation,
per-beat `RDATA`/`RRESP` output banks, valid masks, length outputs, and
selected scalar `RRESP` aggregation.

Lane capture rules are guarded by raw matched queue-head read beat plus the
current beat-count lane index: raw read response event, concrete `RID`,
active queue-head transaction identity, `!request_event`, and beat-count
equality. Queue dequeue and transaction completion still use the generated
`RLAST`-qualified queue-head completion pulse.

Schedule JSON reports
`completion_validity: generated_queue_head_response_demux_last_beat_completion_pulse`,
`beat_match_source: response_demux_matched_read_beat`, `output_shape:
per_beat_output_bank`, `valid_output: per_transaction_valid_mask`,
`length_output: per_transaction_beat_count`, scalar aggregation generated
behavior, `read_data.residue: []`, and `response_demux.residue: []` for the
bounded sample.

The active PNT frontier is now `IAL2-FEATURE-COMPLETENESS-FRONTIER.122`, a
selector/audit for the next queue-head/read-data expansion. Deeper or
multiple queue groups, mixed same-family auto-ID plus concrete queue-head
demux, packed burst-vector outputs, alternate payload assembly, direct
backend, and VHDL remain deferred.
