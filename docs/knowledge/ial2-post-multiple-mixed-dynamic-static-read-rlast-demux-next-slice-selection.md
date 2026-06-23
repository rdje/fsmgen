---
id: ial2-post-multiple-mixed-dynamic-static-read-rlast-demux-next-slice-selection
title: Post multiple mixed read RLAST selector chooses read-data audit
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.304 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.305?"
  - "what is the next IAL2 slice after multiple mixed dynamic/static read RLAST demux?"
  - "why audit scalar read-data after multiple mixed dynamic/static read RLAST demux?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, read-response-demux, read-data, selection]
evidence: docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_DEMUX_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_DATA_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.304|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.305|POST_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_DEMUX_NEXT_SLICE_SELECTION|multiple mixed dynamic/static read-data readiness|generated_multi_mixed_dynamic_static_read_demux_last_beat|multi_static_burst_last_read_data' docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_DEMUX_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/knowledge/ial2-post-multiple-mixed-dynamic-static-read-rlast-demux-next-slice-selection.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.304` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.305`, readiness audit for bounded scalar
read-data over generated multiple mixed dynamic/static read response-demux.

The selector changes no parser, generator, PPIF sample, support accounting,
validation behavior, generated artifacts, tests, schedule/check or semantic
JSON, or HDL behavior.

`.305` is next because `.299` now supplies generated multiple mixed
single-beat `RID` completion pulses and `.303` now supplies generated multiple
mixed burst-last `RID && RLAST` completion pulses. Scalar read-data should
audit how those generated completions map to `RDATA`/`RRESP` capture outputs
before raw `ARLEN` capture, runtime beat-count/`RLAST` validation, multi-beat
output banks, broader mixed cardinalities, same-cycle widening, queues,
scoreboards, direct backend behavior, backend-language variants, or VHDL.
