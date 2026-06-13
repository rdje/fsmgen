---
id: ial2-axi-manager-burst-read-data-contract-selection
title: AXI burst read-data contract selects explicit last-beat capture
answers:
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.57?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.58?"
  - "what burst read-data contract was selected?"
  - "does AXI burst read-data reassembly ship?"
  - "what does capture-scope last-beat mean?"
date: 2026-06-13
status: current
tags: [ial2, axi, manager, read-data, rdata, rresp, burst, rlast, last-beat, selector, task-tree]
evidence: docs/AXI_IAL2_MANAGER_BURST_READ_DATA_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_POST_RLAST_REPORT_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_READ_DATA_BEHAVIOR_FIRST_SLICE.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.58|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.59|capture-scope last-beat|status-policy last-beat|bounded_last_beat_read_data_contract|last-beat-by-rid' docs/AXI_IAL2_MANAGER_BURST_READ_DATA_CONTRACT_SELECTION.md docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_METADATA_FIRST_SLICE.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.57` selected explicit last-beat
read-data capture as the first bounded burst-side public contract and
advanced the frontier to `IAL2-FEATURE-COMPLETENESS-FRONTIER.58`.

The selected syntax extends `(read-data (read ...))` with:

```text
(capture-scope last-beat)
(completion-source response-demux)
(status-policy last-beat)
(interleaving last-beat-by-rid)
```

It is valid only with generated read response demux using
`response_scope burst_last`. The generated response-demux last-beat
completion pulse is the validity strobe for the transaction's last-beat
`RDATA`/`RRESP` outputs.

The selected contract does not ship or select full burst reassembly. It
captures only the matched `RID` beat where `RLAST` is asserted. Per-beat
outputs, packed burst outputs, `RRESP` aggregation across all beats,
`ARLEN`/beat-count validation, fixed-depth storage, per-ID response queues,
direct backend lowering, and VHDL remain residue.

`.58` shipped parser/report metadata and static validation for this contract,
including `ppif/axi_manager_capacity_status_read_data_last_beat.ppif` and
report mode `bounded_last_beat_read_data_contract` with generated behavior
false. Generated last-beat `RDATA`/`RRESP` capture behavior requires the
`.59` readiness audit before implementation; that audit selected `.60`,
direct generated last-beat capture behavior.
