---
id: ial2-multiple-dynamic-read-data-readiness-audit
title: IAL2 multiple dynamic read-data readiness selects contract selection
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.257 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.258?"
  - "is read-data over multiple dynamic read demux ready?"
  - "why select multiple dynamic read-data contract selection?"
date: 2026-06-23
status: current
tags: [ial2, axi, manager, dynamic-id, read-data, readiness]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_DATA_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_DATA_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.257|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.258|MULTIPLE_DYNAMIC_READ_DATA_READINESS_AUDIT|read_data\\.read dynamic coverage requires exactly one dynamic read transaction|bounded scalar read-data over generated multiple dynamic read response-demux' docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_DATA_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.257` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.258`, public contract selection for
bounded scalar read-data over generated multiple dynamic read response-demux.

The audit found the implementation substrate is close: response-demux reports
now expose ordered multiple dynamic read transactions and generated completion
signals, and `read-data.read` normalization already checks transaction
bindings against a coverage list. The blocker is public contract ownership:
the dynamic read-data coverage helper still requires exactly one dynamic read
transaction, and the next slice must choose the exact single-beat/last-beat
source shapes, sample names, report vocabulary, diagnostics, validation, and
residue before implementation.

Burst-length/runtime validation and multi-beat output banks over multiple
dynamic read demux remain later owners behind scalar read-data coverage.
