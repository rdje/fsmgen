---
id: ial2-post-dynamic-write-recapture-next-slice-selection
title: Post dynamic write recapture selector chooses dynamic read recapture contract
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.366 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.367?"
  - "what follows single-active dynamic write same-cycle recapture?"
  - "why is dynamic read recapture contract selection next?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, read, same-cycle, recapture, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_DYNAMIC_WRITE_RECAPTURE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_SAME_CYCLE_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_TRANSACTION_ID_CAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_TRANSACTION_ID_CAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_DATA_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.366|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.367|POST_DYNAMIC_WRITE_RECAPTURE_NEXT_SLICE_SELECTION|single-active dynamic read same-cycle release-and-recapture|bounded_dynamic_read_rid_demux_contract|bounded_dynamic_read_rid_rlast_demux_contract' docs/AXI_IAL2_MANAGER_POST_DYNAMIC_WRITE_RECAPTURE_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.366` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.367`, public contract selection for the
first single-active dynamic read same-cycle release-and-recapture boundary.

The selector changes no parser, generator, PPIF sample, support accounting,
validation behavior, generated artifact, test, JSON, or HDL behavior.

Single-active dynamic read is the closest symmetric sibling after `.365`
because the existing `RID` and `RID && RLAST` dynamic read paths share the same
selected-ID/busy ownership shape as the dynamic write path but still report
request-not-busy. The next owner is contract selection, not direct behavior,
because the read side has two public response scopes and existing dynamic
read-data samples consume generated read completion pulses.

Multiple dynamic write request widening, mixed dynamic/static recapture, static
busy recapture, sibling onehot0 policy, dynamic same-ID queues, scoreboards,
direct backend behavior, backend-language variants, VHDL, and full AXI manager
behavior remain later exact owners.
