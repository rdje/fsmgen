---
id: ial2-mixed-dynamic-static-runtime-validation-readiness-audit
title: IAL2 mixed dynamic/static runtime-validation readiness selects direct implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.288 decide?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.288?"
  - "can mixed dynamic/static runtime beat-count validation be implemented directly?"
  - "does mixed dynamic/static runtime validation need a public contract selection?"
  - "what is the next IAL2 slice after mixed dynamic/static report-only burst-length?"
date: 2026-06-23
status: current
tags: [ial2, axi, manager, dynamic-id, static-id, read-data, burst-length, runtime-validation, readiness]
evidence: docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.288|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.289|MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT|runtime beat-count/RLAST validation|generated_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse|response_demux_matched_read_beat' docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.288` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.289`, direct bounded implementation of
runtime beat-count/`RLAST` validation over generated mixed dynamic/static read
burst-last response-demux and scalar last-beat read-data.

The audit found no lower-layer prerequisite and no separate public
contract-selection need. The existing `burst-length` syntax already covers
`validation runtime-assertion`, and the generic runtime machinery already
derives expected-beat storage, read-beat counters, request-time initialization,
raw matched-read-beat increments, runtime assertions, and report fields once
the mixed dynamic/static coverage predicate admits the runtime shape.

The selected public sample for `.289` is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_burst_length_runtime_assertion.ppif
```

The implementation should preserve the `.287` report-only sample, keep scalar
`RDATA`/`RRESP` capture guarded by generated mixed `RID && RLAST` completion
pulses, and leave mixed multi-beat output banks, multiple mixed transactions,
same-cycle widening, release-and-recapture, dynamic same-ID queues,
scoreboards, direct backend behavior, backend-language variants, and VHDL as
future owners.
