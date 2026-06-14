---
id: ial2-axi-manager-multi-beat-read-data-reassembly-contract-selection
title: AXI multi-beat read-data selector chooses per-beat output banks
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.71 select?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.71?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.72?"
  - "what is the public AXI multi-beat read-data reassembly contract?"
  - "does AXI multi-beat read-data use packed outputs or per-beat outputs?"
  - "does AXI read-data reassembly require runtime-assertion validation?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, read-data, burst, reassembly, per-beat, rresp, selector, task-tree]
evidence: docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_REASSEMBLY_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_POST_BEAT_COUNT_RLAST_VALIDATION_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_FIRST_SLICE.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.71|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.72|MULTI_BEAT_READ_DATA_REASSEMBLY_CONTRACT_SELECTION|capture-scope multi-beat|per-beat output bank|runtime-assertion' docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_REASSEMBLY_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.71` selects the first public AXI
multi-beat read-data reassembly/output contract.

The selected shape is `capture-scope multi-beat` with `interleaving
multi-beat-by-rid`, mandatory ARLEN `burst-length` metadata, and mandatory
`(validation runtime-assertion)`. It uses per-transaction per-beat output
banks: data output prefix, status output prefix, valid-mask output, and length
output. It does not select a packed burst vector or scalar `RRESP`
aggregation.

The next selected leaf is `IAL2-FEATURE-COMPLETENESS-FRONTIER.72`,
parser/report metadata and static validation for the selected syntax. `.72`
must not generate multi-beat storage or output behavior yet.
