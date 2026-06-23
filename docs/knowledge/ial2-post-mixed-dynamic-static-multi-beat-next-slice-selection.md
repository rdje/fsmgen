---
id: ial2-post-mixed-dynamic-static-multi-beat-next-slice-selection
title: IAL2 post mixed dynamic/static multi-beat selector chooses multiple mixed cardinality audit
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.292 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.293?"
  - "what comes after mixed dynamic/static multi-beat output banks?"
  - "what is the next IAL2 slice after mixed dynamic/static multi-beat output banks?"
  - "why is multiple mixed dynamic/static cardinality next?"
date: 2026-06-23
status: current
tags: [ial2, axi, manager, dynamic-id, static-id, response-demux, read-data, multi-beat, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_MULTI_BEAT_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.292|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.293|POST_MIXED_DYNAMIC_STATIC_MULTI_BEAT_NEXT_SLICE_SELECTION|multiple mixed dynamic/static transaction cardinality|multiple mixed dynamic/static transactions' docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_MULTI_BEAT_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/knowledge/ial2-post-mixed-dynamic-static-multi-beat-next-slice-selection.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.292` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.293`, readiness audit for multiple mixed
dynamic/static transaction cardinality after generated mixed dynamic/static
multi-beat output banks.

The selector changes no parser, generator, PPIF sample, support accounting,
validation behavior, generated artifacts, tests, JSON, or HDL behavior.

After `.291`, the one-dynamic plus one-concrete-static mixed dynamic/static
path has write `BID` response-demux, read single-beat `RID` response-demux,
read burst-last `RID && RLAST` response-demux, scalar read-data, report-only
raw-`ARLEN` capture, runtime beat-count/`RLAST` validation, and multi-beat
output-bank behavior.

The next local gap is bounded mixed dynamic/static cardinality widening:
families with more than one dynamic and/or more than one concrete static
transaction. `.293` must audit static concrete-ID reservation lists, dynamic
capture exclusion of all selected static IDs, generated completion lists,
onehot0 same-cycle request policy across more than two selected
transactions, report vocabulary, diagnostics, public sample/support-accounting
names, focused validation, rollback, and residue before any behavior changes.

Same-cycle request widening, same-cycle release-and-recapture, dynamic
same-ID queues, scoreboards, direct backend behavior, backend-language
variants, and VHDL remain later exact owners.
