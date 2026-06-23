---
id: ial2-post-mixed-dynamic-static-read-rlast-demux-next-slice
title: Next owner after mixed dynamic/static read RLAST demux is read-data readiness
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.281 select?"
  - "what comes after mixed dynamic/static read RLAST response-demux?"
  - "why is mixed dynamic/static read-data readiness next?"
  - "does .281 change code or generated behavior?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, read-response-demux, read-data, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_READ_RLAST_DEMUX_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.281|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.282|AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_READ_RLAST_DEMUX_NEXT_SLICE_SELECTION|read-data over generated mixed dynamic/static read response-demux|generated_mixed_dynamic_static_read_demux_last_beat|No parser, generator, PPIF sample, support-accounting catalog, validation behavior, generated artifact, test, schedule/check/semantic JSON, or HDL behavior changed' docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_READ_RLAST_DEMUX_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.281` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.282`, readiness audit for read-data over
generated mixed dynamic/static read response-demux.

The selector follows `.276` and `.280`, which now provide generated mixed
dynamic/static read completion pulses for both single-beat `RID` and
burst-last `RID && RLAST` response-demux. The next dependency is scalar
read-data coverage over those generated completions before burst-length,
runtime beat-count/`RLAST`, or multi-beat output-bank behavior can be selected.

The current read-data coverage helper has branches for generated auto-ID,
queue-head, mixed auto-ID plus queue-head, and all-dynamic response-demux
families, but no branch for `generated_mixed_dynamic_static_read_demux` or
`generated_mixed_dynamic_static_read_demux_last_beat`. `.282` must decide
whether the next owner can implement scalar mixed read-data directly or needs
public contract selection first.

`.281` is a docs/continuity selector only. It changes no parser, generator,
PPIF sample, support-accounting catalog, validation behavior, generated
artifact, test, schedule/check/semantic JSON, or HDL behavior.
