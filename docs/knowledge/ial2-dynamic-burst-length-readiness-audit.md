---
id: ial2-dynamic-burst-length-readiness-audit
title: Dynamic burst-length readiness selects direct report-only ARLEN implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.237 select?"
  - "can dynamic read-data report-only burst-length ship directly?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.238?"
  - "does dynamic burst-length need a new public contract?"
  - "what remains deferred after the dynamic burst-length readiness audit?"
date: 2026-06-22
status: current
tags: [ial2, axi, dynamic-id, read-data, burst-length, arlen, readiness]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_BURST_LENGTH_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_DYNAMIC_FOCUSED_SUITE_CLEANUP.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_DATA_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_TRANSACTION_ID_CAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_METADATA_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_ARLEN_CAPTURE_BEHAVIOR_FIRST_SLICE.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.237|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.238|DYNAMIC_BURST_LENGTH_READINESS_AUDIT|dynamic raw-ARLEN|generated_dynamic_demux_last_beat|burst_length_generated_behavior|t/1438-axi-ial2-manager-dynamic-transaction-id-focused' docs/AXI_IAL2_MANAGER_DYNAMIC_BURST_LENGTH_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.237` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.238`, direct bounded implementation of
report-only raw-`ARLEN` burst-length capture over generated single-active
dynamic read burst-last response-demux plus scalar last-beat dynamic
read-data.

No new public contract selector is required for the selected shape. The
existing `read-data.read` `burst-length` syntax already owns `source arlen`,
width-8 signal metadata, `axlen-plus-one` encoding, request capture,
`max-beats` in `1..256`, and `report-only` versus `runtime-assertion`
vocabulary.

The implementation substrate is already adjacent: burst-length normalization,
per-transaction raw-`ARLEN` storage names, request-guarded capture rules,
generated input/report artifact lists, and read-data report helpers exist for
non-dynamic last-beat and queue-head shapes. The current dynamic coverage gate
is the local blocker because it admits dynamic single-beat or last-beat
read-data only when no `burst_length` metadata is present.

`.238` now ships that selected report-only dynamic raw-`ARLEN` capture.
Dynamic runtime validation, dynamic multi-beat output banks, multiple or
mixed dynamic demux, same-cycle recapture, dynamic same-ID ordering, queues,
scoreboards, direct backend behavior, and VHDL remain deferred; `.239` audits
dynamic runtime-validation readiness next.
