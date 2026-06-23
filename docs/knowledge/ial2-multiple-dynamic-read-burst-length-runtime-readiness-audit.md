---
id: ial2-multiple-dynamic-read-burst-length-runtime-readiness-audit
title: IAL2 multiple dynamic read burst-length runtime readiness selects contract
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.261 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.261?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.262?"
  - "is burst-length runtime over multiple dynamic read demux ready?"
  - "why select multiple dynamic burst-length runtime contract selection?"
date: 2026-06-23
status: current
tags: [ial2, axi, manager, dynamic-id, read-data, burst-length, runtime-validation, selector]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_RUNTIME_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_READ_DATA_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_RUNTIME_VALIDATION_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_BURST_LENGTH_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.261|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.262|MULTIPLE_DYNAMIC_READ_BURST_LENGTH_RUNTIME_READINESS_AUDIT|dynamic burst-length or multi-beat coverage requires exactly one dynamic read transaction|public contract selection for bounded burst-length and runtime beat-count' docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_RUNTIME_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.261` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.262`, public contract selection for
bounded burst-length and runtime beat-count/`RLAST` validation over generated
multiple dynamic read response-demux.

The audit found the lower implementation helpers are close after coverage
admission: burst-length metadata normalization, per-transaction raw-`ARLEN`
storage and capture rule naming, expected-beat and read-beat counter storage,
beat-count rule and assertion emission, matched-read-beat expressions, and
read-data report/generated-artifact aggregation are already transaction-list
shaped.

The current dynamic coverage gate still fails closed when burst-length/runtime
metadata is attached to more than one generated dynamic read transaction. A
temporary mutation of the `.259` last-beat multiple dynamic read-data sample
with runtime burst-length metadata failed at the expected diagnostic.

Contract selection is needed before implementation to settle public sample
names, whether report-only raw-`ARLEN` capture and runtime validation ship
together or split, exact transaction coverage, per-transaction request-time
`ARLEN` ownership, beat-counter and assertion semantics, report vocabulary,
diagnostics, validation, rollback, and explicit residue.

The `.261` audit changed no parser, generator, PPIF sample,
support-accounting catalog, validation behavior, generated artifact, test,
schedule/check or semantic JSON, or HDL behavior.
