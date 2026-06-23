---
id: ial2-broader-mixed-dynamic-static-cardinality-readiness
title: Broader mixed dynamic/static cardinality needs contract selection
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.316 select?"
  - "can broader mixed dynamic/static cardinality be implemented directly?"
  - "what comes after the broader mixed dynamic/static cardinality audit?"
  - "why does broader mixed dynamic/static cardinality need contract selection?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, response-demux, read-data, audit]
evidence: docs/AXI_IAL2_MANAGER_BROADER_MIXED_DYNAMIC_STATIC_CARDINALITY_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_MULTI_BEAT_NEXT_SLICE_SELECTION.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.316|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.317|BROADER_MIXED_DYNAMIC_STATIC_CARDINALITY_READINESS_AUDIT|requires exactly one dynamic|mixed dynamic/static ID matching supports exactly one dynamic' docs/AXI_IAL2_MANAGER_BROADER_MIXED_DYNAMIC_STATIC_CARDINALITY_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.316` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.317`, public contract selection for the
first broader mixed dynamic/static transaction-cardinality shape.

Direct implementation is not selected because the current response-demux
admission gates, mixed demux constructors, read burst-last normalizer,
read-data coverage predicates, and multi-beat residue predicates all encode
the exact one-dynamic plus one- or two-concrete-static boundary.

`.317` must choose the first public broader shape, possible sample/support
accounting stems, report vocabulary, diagnostics, validation strategy, and
explicit residue before any parser/generator/test/HDL behavior changes.
