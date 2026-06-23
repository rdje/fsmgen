---
id: ial2-post-multiple-mixed-write-demux-next-slice-selection
title: IAL2 post multiple mixed write demux selector chooses read readiness
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.296 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.297?"
  - "what comes after multiple mixed dynamic/static write demux?"
  - "why select multiple mixed dynamic/static read readiness after multiple mixed write demux?"
  - "what remains residue after multiple mixed dynamic/static write demux shipped?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, read-response-demux, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_DEMUX_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_RESPONSE_DEMUX_READINESS_AUDIT.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.296|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.297|POST_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_DEMUX_NEXT_SLICE_SELECTION|multiple mixed dynamic/static read response-demux|bounded_multi_mixed_dynamic_static_read_rid_demux_contract|exactly one dynamic read transaction and one concrete static read transaction' docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_DEMUX_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.296` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.297`, readiness audit for multiple mixed
dynamic/static read response-demux after generated bounded multiple mixed
dynamic/static write `BID` response-demux shipped.

The selector changes no behavior. It records that `.295` settled the first
widened mixed ownership and report contract on write `BID` response-demux,
including list-shaped mixed transaction/static-ID reservation fields and
dynamic capture exclusions for every selected static concrete ID.

The next parity gap is read response-demux. The current read plan builder is
still singular and fails closed for one dynamic plus two concrete static reads
with the diagnostic that mixed dynamic/static read matching supports exactly
one dynamic read transaction and one concrete static read transaction in this
slice. `.297` should audit whether the next owner should select single-beat
`RID`, burst-last `RID && RLAST`, both read scopes, direct implementation, or
a narrower prerequisite.

Further write cardinality, read-data over multiple mixed reads,
burst-length/runtime validation, multi-beat output banks, same-cycle request
widening, release-and-recapture, dynamic same-ID queues, scoreboards, direct
backend behavior, backend-language variants, and VHDL remain future exact
owners.
