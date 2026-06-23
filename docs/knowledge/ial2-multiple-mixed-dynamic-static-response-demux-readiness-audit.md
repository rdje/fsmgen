---
id: ial2-multiple-mixed-dynamic-static-response-demux-readiness-audit
title: IAL2 multiple mixed dynamic/static readiness selects write demux contract
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.293 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.294?"
  - "is multiple mixed dynamic/static response-demux ready for direct implementation?"
  - "why does multiple mixed dynamic/static start with write demux contract selection?"
  - "what diagnostic does multiple mixed dynamic/static read demux currently emit?"
date: 2026-06-23
status: current
tags: [ial2, axi, manager, dynamic-id, static-id, response-demux, readiness-audit]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_RESPONSE_DEMUX_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_MULTI_BEAT_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.293|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.294|MULTIPLE_MIXED_DYNAMIC_STATIC_RESPONSE_DEMUX_READINESS_AUDIT|multiple mixed dynamic/static write|exactly one dynamic read transaction and one concrete static read transaction' docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_RESPONSE_DEMUX_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.293` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.294`, public contract selection for
bounded multiple mixed dynamic/static write `BID` response-demux.

The audit changes no parser, generator, PPIF sample, support accounting,
validation behavior, generated artifacts, tests, JSON, or HDL behavior.

The current mixed dynamic/static implementation is hard-bounded to exactly
one dynamic transaction and one concrete static transaction. A temporary
one-dynamic plus two-concrete-static read-demux candidate failed closed with:

```text
AXI manager capacity/status IAL2 contract response_demux.read mixed dynamic/static ID matching supports exactly one dynamic read transaction and one concrete static read transaction in this slice
```

The audit found that mixed assertion generation is already list-shaped, but
the mixed write/read plan builders and read-data coverage predicates still
use singular dynamic/static state and singular static-ID reservation fields.

The next owner is a contract selection, not direct implementation, because
the source/report contract must first settle first bounded cardinality,
static concrete-ID reservation lists, dynamic capture exclusion against every
selected static ID, onehot0 request policy across all selected transactions,
generated completion ordering, diagnostics, support-accounting identity, and
residue.

Write `BID` response-demux is selected first because it is the smallest
cardinality-widened ownership surface. Read response-demux, `RLAST`,
read-data, burst-length/runtime validation, multi-beat output banks,
same-cycle widening, release-and-recapture, dynamic same-ID queues,
scoreboards, direct backend behavior, backend-language variants, and VHDL
remain later exact owners.
