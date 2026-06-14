---
id: ial2-axi-manager-multi-beat-read-data-reassembly-contract-selection
title: AXI multi-beat read-data selector chooses per-beat output banks
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.71 select?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.71?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.72?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.72?"
  - "what is the public AXI multi-beat read-data reassembly contract?"
  - "does AXI multi-beat read-data use packed outputs or per-beat outputs?"
  - "does AXI read-data reassembly require runtime-assertion validation?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, read-data, burst, reassembly, per-beat, rresp, selector, task-tree]
evidence: docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_REASSEMBLY_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_METADATA_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_OUTPUT_BANK_BEHAVIOR_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_POST_BEAT_COUNT_RLAST_VALIDATION_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_FIRST_SLICE.md; ppif/axi_manager_capacity_status_read_data_multi_beat.ppif; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.71|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.72|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.73|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.74|MULTI_BEAT_READ_DATA_REASSEMBLY_CONTRACT_SELECTION|MULTI_BEAT_READ_DATA_METADATA_FIRST_SLICE|MULTI_BEAT_READ_DATA_OUTPUT_BANK_BEHAVIOR_FIRST_SLICE|capture-scope multi-beat|per-beat output bank|runtime-assertion' docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_REASSEMBLY_CONTRACT_SELECTION.md docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_METADATA_FIRST_SLICE.md docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_OUTPUT_BANK_BEHAVIOR_FIRST_SLICE.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.71` selects the first public AXI
multi-beat read-data reassembly/output contract.

The selected shape is `capture-scope multi-beat` with `interleaving
multi-beat-by-rid`, mandatory ARLEN `burst-length` metadata, and mandatory
`(validation runtime-assertion)`. It uses per-transaction per-beat output
banks: data output prefix, status output prefix, valid-mask output, and length
output. It does not select a packed burst vector or scalar `RRESP`
aggregation.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.72` shipped parser/report metadata and
static validation for the selected syntax. It accepts the public `.ppif`
shape and reports lane names, valid-mask widths, length-output widths, and
`multi_beat_reassembly_generated_behavior: false` without generating
multi-beat payload storage or output behavior.

The follow-up leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.73` completed a
readiness audit and selected `IAL2-FEATURE-COMPLETENESS-FRONTIER.74`,
generated multi-beat read-data output-bank behavior. `.74` has since shipped
the selected behavior and schedule JSON now reports
`multi_beat_reassembly_generated_behavior: true` with generated payload
inputs, output-bank outputs, output-init rules, and per-lane capture rules.
