---
id: ial2-dynamic-runtime-validation-readiness-audit
title: Dynamic runtime validation readiness selects direct generated implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.239 select?"
  - "can dynamic runtime beat-count validation be implemented directly?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.240?"
  - "does dynamic runtime validation need a new public contract?"
  - "what remains deferred after the dynamic runtime validation readiness audit?"
date: 2026-06-22
status: current
tags: [ial2, axi, dynamic-id, read-data, burst-length, runtime-validation, readiness]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_RUNTIME_VALIDATION_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_DYNAMIC_BURST_LENGTH_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_BURST_LENGTH_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_TRANSACTION_ID_CAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_FIRST_SLICE.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.239|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.240|DYNAMIC_RUNTIME_VALIDATION_READINESS|generated_dynamic_read_response_demux_last_beat_completion_pulse|runtime_assertion|response_demux_matched_read_beat|dynamic runtime-validation sample' docs/AXI_IAL2_MANAGER_DYNAMIC_RUNTIME_VALIDATION_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.239` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.240`, direct bounded implementation of
generated dynamic runtime beat-count/`RLAST` validation over the shipped
single-active dynamic read burst-last response-demux, scalar last-beat
dynamic read-data, and report-only raw-`ARLEN` capture boundary.

No new public contract selector is required. The existing `read-data.read`
`burst-length` syntax already accepts `validation runtime-assertion`, and the
runtime helper substrate already creates expected beat-count storage,
read-beat counters, request-time initialization, matched-read-beat increment
rules, four assertions, report fields, and residue cleanup for non-dynamic
runtime-validation families.

The current implementation blocker is local to the dynamic coverage gate: the
`.238` report-only dynamic sample works, while changing that sample in memory
to `runtime-assertion` fails at the dynamic coverage diagnostic. The parser,
normalizer, and runtime helper vocabulary are already adjacent.

`.240` is the exact next owner for one generated single-active dynamic
read-last-beat runtime-validation shape. Dynamic multi-beat output banks,
multiple/mixed dynamic demux, same-cycle recapture, dynamic same-ID ordering,
queues, scoreboards, direct backend behavior, backend-language variants, and
VHDL remain deferred.
