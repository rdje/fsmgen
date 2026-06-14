---
id: ial2-axi-manager-post-beat-count-rlast-validation-next-slice-selection
title: Post beat-count/RLAST selector chooses read-data reassembly contract selection
answers:
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.70?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.70 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.71?"
  - "why is AXI read-data reassembly not implemented immediately after beat-count validation?"
  - "what remains after AXI beat-count/RLAST runtime validation?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, read-data, burst, reassembly, rresp, selector, task-tree]
evidence: docs/AXI_IAL2_MANAGER_POST_BEAT_COUNT_RLAST_VALIDATION_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_REASSEMBLY_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_FIRST_SLICE.md; ppif/axi_manager_capacity_status_read_data_burst_length_runtime_assertion.ppif; ppif/axi_manager_capacity_status_read_data_burst_length.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.70|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.71|POST_BEAT_COUNT_RLAST_VALIDATION_NEXT_SLICE_SELECTION|multi-beat read-data reassembly/output contract' docs/AXI_IAL2_MANAGER_POST_BEAT_COUNT_RLAST_VALIDATION_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.70` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.71` as the next exact owner.

`.71` owns public AXI multi-beat read-data reassembly/output contract
selection after generated beat-count/RLAST runtime validation. It is
selector-only: no parser, generator, HDL, sample, support-accounting, check
JSON, semantic JSON, or validation behavior changes are selected for `.70`.
`.71` has since selected the per-beat output-bank public contract and handed
off to `.72`, parser/report metadata and static validation.

The reason is that `.69` proves expected beat count and `RLAST` validation,
but the public source/report surface still does not define bounded payload
storage, per-beat outputs, packed outputs, length/valid outputs, all-beat
`RRESP` aggregation, or different-ID/per-ID queue semantics.

The `.69` runtime path leaves `read_data.residue` as
`multi_beat_read_data_reassembly`, `per_beat_outputs`, and
`rresp_aggregation`. Report-only burst-length contracts still keep
`generated_beat_count_validation` because they generate no runtime checks.
