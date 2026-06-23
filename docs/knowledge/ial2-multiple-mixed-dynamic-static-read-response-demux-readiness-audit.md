---
id: ial2-multiple-mixed-dynamic-static-read-response-demux-readiness-audit
title: IAL2 multiple mixed dynamic/static read readiness selects single-beat contract
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.297 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.298?"
  - "is multiple mixed dynamic/static read response-demux ready for direct implementation?"
  - "why start multiple mixed dynamic/static read widening with single-beat RID?"
  - "what remains residue after multiple mixed dynamic/static read readiness?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, read-response-demux, readiness]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_DEMUX_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.297|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.298|MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_READINESS_AUDIT|bounded_multi_mixed_dynamic_static_read_rid_demux_contract|axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static|exactly one dynamic read transaction and one concrete static read transaction' docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.297` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.298`, public contract selection for
bounded multiple mixed dynamic/static read single-beat `RID` response-demux.

The audit changes no behavior. It finds the implementation substrate close
but contract-sensitive: `.295` provides the list-shaped multi-static write
pattern and the mixed assertion helper is already list-shaped, but the read
plan builder remains singular and the read family has separate single-beat
`RID` and burst-last `RID && RLAST` semantics.

The first read-side widening starts with single-beat `RID` because it is the
smallest read surface that exercises the widened mixed ownership problem
without adding final-beat `RLAST`, raw-beat assertions, read-data,
burst-length/runtime validation, or multi-beat output-bank behavior.

`.298` should select the source/report contract for one dynamic read
transaction plus two concrete static read transactions, likely through
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static.ppif`,
candidate mode `bounded_multi_mixed_dynamic_static_read_rid_demux_contract`,
candidate completion source `generated_multi_mixed_dynamic_static_read_demux`,
list-shaped mixed transaction/static-ID reservation fields, dynamic capture
exclusions for every selected static ID, and preserved `.276` one-dynamic
plus one-static report shape.
