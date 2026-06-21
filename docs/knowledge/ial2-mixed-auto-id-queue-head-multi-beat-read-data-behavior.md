---
id: ial2-mixed-auto-id-queue-head-multi-beat-read-data-behavior
title: IAL2 .207 ships mixed auto-ID queue-head multi-beat read-data
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.207 ship?"
  - "is mixed auto-id queue-head multi-beat read-data supported?"
  - "which PPIF sample covers mixed auto-id queue-head multi-beat output banks?"
  - "does mixed multi-beat read-data over queue-head remove read_data residue?"
date: 2026-06-21
status: current
tags: [ial2, axi, manager, auto-id, same-id, queue-head, multi-beat, read-data, behavior]
evidence: docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR.md; ppif/axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_multi_beat_read_data.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
reverify: ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_multi_beat_read_data.ppif | rg 'bounded_multi_beat_read_data_contract|generated_mixed_auto_id_queue_head_response_demux_last_beat_completion_pulse|generated_multi_beat_capture_rules|\"residue\"'
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.207` ships support-accounted generated
multi-beat read-data output-bank behavior for
`ppif/axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_multi_beat_read_data.ppif`.

The sample covers one read auto-ID transaction plus one depth-2 concrete
same-ID queue-head read group over the selected mixed read burst-last
runtime-validation shape. It reports the mixed last-beat completion validity,
three covered read transactions, 48 generated `RDATA` lanes, 48 generated
`RRESP` lanes, three valid masks, three length outputs, three scalar `RRESP`
aggregate outputs, 48 lane-capture rules, runtime beat-count/`RLAST`
assertions, strict support accounting, semantic JSON support, HDL, and empty
`read_data.residue`.
