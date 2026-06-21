---
id: ial2-mixed-auto-id-queue-head-runtime-validation-behavior
title: IAL2 .202 ships mixed auto-ID queue-head runtime validation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.202 ship?"
  - "is mixed auto-id queue-head runtime validation supported?"
  - "which PPIF sample covers mixed auto-id queue-head runtime validation?"
  - "does mixed runtime validation remove generated_beat_count_validation residue?"
date: 2026-06-21
status: current
tags: [ial2, axi, manager, auto-id, same-id, queue-head, runtime-validation, behavior]
evidence: docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md; ppif/axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length_runtime_assertion.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
reverify: ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length_runtime_assertion.ppif | rg 'runtime_assertion|generated_beat_count_assertions|response_demux_matched_read_beat'
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.202` ships support-accounted generated
runtime beat-count/`RLAST` validation for
`ppif/axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length_runtime_assertion.ppif`.

The sample covers one read auto-ID transaction plus one depth-2 concrete
same-ID queue-head read group over the mixed read burst-last scalar last-beat
shape. It emits raw `ARLEN` storage, expected-beat storage, read-beat
counters, request-time initialization rules, matched-read-beat increment
rules, and twelve beat-count/`RLAST` assertions for `r0`, `r1`, and `r2`.
Schedule/check/semantic JSON report strict support under the new
support-accounting entry, and the runtime sample removes
`generated_beat_count_validation` from `read_data.residue`. Mixed multi-beat
output banks remain separately owned.
