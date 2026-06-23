---
id: ial2-post-multiple-dynamic-read-data-next-slice-selection
title: IAL2 post multiple dynamic read-data selector chooses runtime audit
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.260 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.260?"
  - "why audit multiple dynamic burst-length runtime readiness next?"
  - "what comes after multiple dynamic read-data behavior?"
date: 2026-06-23
status: current
tags: [ial2, axi, manager, dynamic-id, read-data, burst-length, runtime-validation, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_READ_DATA_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_RUNTIME_VALIDATION_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_BURST_LENGTH_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_MULTI_BEAT_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.260|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.261|POST_MULTIPLE_DYNAMIC_READ_DATA_NEXT_SLICE_SELECTION|burst-length/runtime validation over generated multiple dynamic read response-demux|multi-beat output-bank widening depends on per-transaction raw-`ARLEN` capture' docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_READ_DATA_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.260` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.261`, readiness audit for generated
burst-length and runtime beat-count/`RLAST` validation over generated multiple
dynamic read response-demux.

The selector chose an audit because `.259` shipped scalar read-data over
multiple dynamic read demux, but the next behavior needs request-time
raw-`ARLEN` capture, expected-beat state, read-beat counters, and assertion
semantics across multiple active dynamic read transactions. Multi-beat
output-bank widening depends on that burst-length/runtime boundary.

The `.261` audit must decide whether report-only raw-`ARLEN` capture and
runtime validation can be implemented directly, need public contract
selection, or need helper/report cleanup first. It must not change parser,
generator, samples, support accounting, generated artifacts, tests,
schedule/check/semantic JSON, or HDL behavior unless it first selects a later
owner.
