---
id: ial2-post-three-static-mixed-dynamic-static-read-rlast-demux-next-slice-selection
title: Post three-static mixed read RLAST selector chooses read-data audit
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.327 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.328?"
  - "what is next after three-static mixed read RLAST demux?"
  - "why audit three-static mixed read-data after RLAST demux?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, read, rlast, read-data, selection]
evidence: docs/AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_DEMUX_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_READINESS_AUDIT.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.327|IAL2-FEATURE-COMPLETENESS-FRONTIER\.328|POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_DEMUX_NEXT_SLICE_SELECTION|three-static mixed read-data|multi_static3_burst_last_read_data' docs/AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_DEMUX_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/knowledge/ial2-post-three-static-mixed-dynamic-static-read-rlast-demux-next-slice-selection.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.327` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.328`, readiness audit for bounded scalar
read-data over generated one-dynamic plus three-concrete-static mixed
dynamic/static read response-demux.

The selector changes no parser, generator, PPIF sample, support accounting,
validation behavior, generated artifacts, tests, schedule/check or semantic
JSON, or HDL behavior.

`.328` is next because `.322` now supplies generated three-static mixed
single-beat `RID` completion pulses and `.326` now supplies generated
three-static mixed burst-last `RID && RLAST` completion pulses. Scalar
read-data should audit how those generated completions map to `RDATA`/`RRESP`
capture outputs before raw `ARLEN` capture, runtime beat-count/`RLAST`
validation, multi-beat output banks, broader mixed cardinalities, same-cycle
widening, queues, scoreboards, direct backend behavior, backend-language
variants, or VHDL.
