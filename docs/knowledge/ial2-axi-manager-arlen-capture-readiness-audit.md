---
id: ial2-axi-manager-arlen-capture-readiness-audit
title: AXI ARLEN capture audit selects generated raw-ARLEN behavior
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.65 decide?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.65?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.66?"
  - "should generated burst-length capture store raw ARLEN or beat count?"
date: 2026-06-13
status: current
tags: [ial2, axi, manager, read-data, burst-length, arlen, capture, readiness, behavior, task-tree]
evidence: docs/AXI_IAL2_MANAGER_ARLEN_CAPTURE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_ARLEN_CAPTURE_BEHAVIOR_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_POST_BURST_LENGTH_METADATA_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_METADATA_FIRST_SLICE.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.65|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.66|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.67|raw-ARLEN|ARLEN_CAPTURE_READINESS|generated raw-ARLEN' docs/AXI_IAL2_MANAGER_ARLEN_CAPTURE_READINESS_AUDIT.md docs/AXI_IAL2_MANAGER_ARLEN_CAPTURE_BEHAVIOR_FIRST_SLICE.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.65` audited generated AXI ARLEN
burst-length capture readiness and selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.66`, generated raw-ARLEN capture
behavior.

The audit found no new IAL1/IAL0/SystemVerilog substrate prerequisite for a
bounded capture slice. Existing generated inputs, generated vars, guarded
rules, request-event guards, same-family request mutual-exclusion assertions,
report artifact lists, and HDL lowering are sufficient.

The selected behavior stores raw 8-bit `ARLEN` per covered read transaction,
not `ARLEN + 1`. The report keeps `burst_length_encoding: axlen_plus_one` for
later validation/reassembly owners. `.66` shipped the generated
input/storage/rule reachability and `generated_burst_length_capture` residue
removal, then selected `.67`, beat-count/RLAST validation readiness.
