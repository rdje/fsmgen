---
id: ial2-multiple-dynamic-read-response-demux-readiness-audit
title: Multiple dynamic read demux readiness selects contract selection
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.249 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.250?"
  - "is multiple dynamic read response-demux ready for direct implementation?"
  - "why select multiple dynamic read response-demux contract selection?"
date: 2026-06-22
status: current
tags: [ial2, axi, dynamic-id, read-response-demux, readiness, selection]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_WRITE_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.249|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.250|MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_READINESS_AUDIT|public contract selection for bounded multiple dynamic read response-demux|_response_demux_dynamic_read_transaction|_response_demux_dynamic_assertion_specs_for_family' docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.249` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.250`, public contract selection for
bounded multiple dynamic read response-demux behavior.

The audit found that the lower response-demux substrate is partly list-shaped:
dynamic storage, capture/release, response rules, and family-generic dynamic
assertions can represent multiple states after normalization admits them. The
hard boundary is still public semantics and normalization. The read helper
accepts exactly one dynamic read transaction and no additional read
transactions, while dynamic read-data coverage expects one dynamic read and
one generated completion signal.

Contract selection is required before implementation because the read side
must define `single_beat` versus `burst_last` scope, optional `RLAST`, raw
matched `RID` beat assertions, read-data interaction, burst-length/runtime
validation, and multi-beat output-bank residue before behavior widens.
