---
id: ial2-post-multiple-dynamic-multi-beat-next-slice-selection
title: IAL2 post multiple dynamic multi-beat selector chooses mixed dynamic/static demux audit
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.269 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.270?"
  - "what comes after multiple dynamic multi-beat output banks?"
  - "what is the next dynamic IAL2 owner after multiple dynamic multi-beat?"
date: 2026-06-23
status: current
tags: [ial2, axi, manager, dynamic-id, response-demux, mixed-dynamic-static, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_MULTI_BEAT_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_MULTI_BEAT_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.269|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.270|POST_MULTIPLE_DYNAMIC_MULTI_BEAT_NEXT_SLICE_SELECTION|mixed dynamic/static response-demux|mixed dynamic/static response demux' docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_MULTI_BEAT_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md docs/knowledge/ial2-post-multiple-dynamic-multi-beat-next-slice-selection.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.269` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.270`, readiness audit for mixed
dynamic/static response-demux behavior after generated bounded multiple
dynamic multi-beat read-data output banks.

The selector changes no parser, generator, PPIF sample, support accounting,
validation behavior, generated artifacts, tests, JSON, or HDL behavior.

After `.268`, the all-dynamic multiple dynamic path has write response-demux,
read single-beat response-demux, read burst-last/`RLAST` response-demux,
scalar read-data, report-only raw-`ARLEN` capture, runtime beat-count/`RLAST`
validation, and multi-beat output-bank behavior. The next local response
ownership gap is mixed dynamic/static response-demux, where one raw response
could match both static concrete-ID state and active dynamic captured-ID
state unless the public ownership/assertion contract is selected first.
