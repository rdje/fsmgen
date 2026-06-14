---
id: ial2-axi-manager-post-burst-length-metadata-next-slice-selection
title: AXI post burst-length metadata selector chooses ARLEN capture readiness
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.64 select?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.64?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.65?"
  - "why is generated ARLEN capture audited before implementation?"
date: 2026-06-13
status: current
tags: [ial2, axi, manager, read-data, burst-length, arlen, capture, readiness, selector, task-tree]
evidence: docs/AXI_IAL2_MANAGER_POST_BURST_LENGTH_METADATA_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_METADATA_FIRST_SLICE.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.64|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.66|generated ARLEN|raw-ARLEN|AXI_IAL2_MANAGER_POST_BURST_LENGTH_METADATA_NEXT_SLICE_SELECTION' docs/AXI_IAL2_MANAGER_POST_BURST_LENGTH_METADATA_NEXT_SLICE_SELECTION.md docs/AXI_IAL2_MANAGER_ARLEN_CAPTURE_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.64` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.65`, a readiness audit for generated AXI
ARLEN burst-length capture.

Generated ARLEN capture is the next prerequisite before beat-count/RLAST
validation, beat indexing, storage, or multi-beat read-data reassembly.
The selector chose an audit before implementation because generated capture
adds a new opt-in HDL input, generated transaction-local storage, and
request-event binding. The audit must decide raw-ARLEN versus derived
beat-count storage, width/name/report contracts, simultaneous-request
diagnostics, generated artifact boundaries, validation gates, rollback, and
VHDL deferral.

No parser, generator, HDL, sample, support-accounting, check JSON, semantic
JSON, or validation behavior changed in `.64`.

The `.65` audit then selected `.66`, generated raw-ARLEN capture behavior, as
the next active frontier.
