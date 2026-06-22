---
id: ial2-post-dynamic-runtime-validation-next-slice-selection
title: Post dynamic runtime selector chooses dynamic multi-beat readiness
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.241 select?"
  - "what comes after dynamic runtime validation?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.242?"
  - "why is dynamic multi-beat output-bank readiness next?"
  - "does the post dynamic runtime selector change behavior?"
date: 2026-06-22
status: current
tags: [ial2, axi, dynamic-id, read-data, runtime-validation, multi-beat, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_DYNAMIC_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_RUNTIME_VALIDATION_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_RUNTIME_VALIDATION_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_DYNAMIC_BURST_LENGTH_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_DATA_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/knowledge/ial2-dynamic-runtime-validation-behavior.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.241|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.242|POST_DYNAMIC_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION|dynamic multi-beat output-bank readiness|generated_dynamic_demux_last_beat|multi_beat_read_data_reassembly' docs/AXI_IAL2_MANAGER_POST_DYNAMIC_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/knowledge/ial2-post-dynamic-runtime-validation-next-slice-selection.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.241` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.242`, readiness audit for generated
dynamic multi-beat read-data output-bank behavior over the selected
single-active dynamic read runtime-validation boundary.

The selector changes no parser, generator, PPIF sample, support accounting,
validation behavior, generated artifacts, tests, schedule/check or semantic
JSON, or HDL behavior.

Dynamic multi-beat readiness is next because `.240` now leaves the same
read-data residue that prior non-dynamic lanes resolved after runtime
validation: `multi_beat_read_data_reassembly`, `per_beat_outputs`, and
`rresp_aggregation`. The shipped dynamic runtime sample already provides raw
matched-`RID` beat counting and expected-beat state; `.242` must audit the
exact public multi-beat boundary before any behavior-bearing widening.

Multiple/mixed dynamic demux, same-cycle recapture, dynamic same-ID ordering,
queues, scoreboards, direct backend behavior, backend-language variants, and
VHDL remain deferred.
