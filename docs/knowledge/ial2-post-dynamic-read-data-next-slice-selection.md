---
id: ial2-post-dynamic-read-data-next-slice-selection
title: Post dynamic read-data selector chooses focused-suite cost cleanup
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.235 select?"
  - "what comes after scalar dynamic read-data?"
  - "why is AXI manager test-cost cleanup next?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.236?"
date: 2026-06-22
status: current
tags: [ial2, axi, dynamic-id, validation, tests, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_DATA_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_DATA_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/knowledge/ial2-dynamic-read-data-behavior.md; docs/knowledge/ial2-feature-completeness-priority.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.235|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.236|POST_DYNAMIC_READ_DATA_NEXT_SLICE_SELECTION|focused-suite cost cleanup|host-memory cutoff|t/1437|t/1436' docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_DATA_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/knowledge/ial2-dynamic-read-data-behavior.md docs/knowledge/ial2-feature-completeness-priority.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.235` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.236`, AXI manager focused-suite cost
cleanup before further dynamic behavior expansion.

The selector does not change parser, generator, PPIF sample, support
accounting, validation behavior, generated artifacts, tests, schedule/check or
semantic JSON, or HDL behavior.

The reason is validation quality. `.234` shipped scalar dynamic read-data
through direct parser/generator, schedule/check/semantic, HDL, support
accounting, docs, Knowledge Map, memory, and doctrine probes, but the full AXI
manager monoliths are no longer routine closeout surfaces: `t/1437` became
CPU-bound in pre-existing regex-heavy assertions, and a guarded full `t/1436`
rerun reached the host-memory cutoff.

`.236` must make the shipped dynamic transaction-ID family from `.219` through
`.234` runnable through bounded focused validation before dynamic
burst-length, runtime validation, multi-beat output banks, multiple/mixed
dynamic demux, same-cycle recapture, dynamic same-ID ordering, queues,
scoreboards, direct backend behavior, or VHDL is widened.
