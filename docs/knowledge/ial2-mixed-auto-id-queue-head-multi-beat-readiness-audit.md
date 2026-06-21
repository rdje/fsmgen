---
id: ial2-mixed-auto-id-queue-head-multi-beat-readiness-audit
title: Mixed auto-ID queue-head multi-beat readiness selects implementation
answers:
  - "can mixed auto-id queue-head multi-beat read-data ship directly?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.206 select?"
  - "what blocks mixed multi-beat read-data before .207?"
  - "what is the next IAL2 slice after mixed multi-beat readiness?"
date: 2026-06-21
status: current
tags: [ial2, axi, manager, mixed-auto-id, queue-head, multi-beat, readiness]
evidence: docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_MULTI_BEAT_READINESS_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.206|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.207|MIXED_AUTO_ID_QUEUE_HEAD_MULTI_BEAT_READINESS_AUDIT|mixed auto-ID plus queue-head coverage requires|generated_mixed_auto_id_queue_head_response_demux_last_beat_completion_pulse' docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_MULTI_BEAT_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm README.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.206` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.207`, direct bounded implementation of
generated multi-beat output-bank behavior over the `.202` same-family mixed
auto-ID plus depth-2 concrete same-ID queue-head read burst-last
runtime-validation shape.

The audit found no parser, IAL1, IAL0, SystemVerilog, report, or
support-accounting prerequisite. A temporary multi-beat mutation of the `.202`
sample fails only at the local mixed read-data coverage predicate, which still
admits that mixed transaction set only for `single-beat` and `last-beat`.
After admission, existing transaction-list helpers already generate the
expected multi-beat output-bank, scalar `RRESP` aggregate, burst-length,
beat-count, assertion, and report artifacts.
