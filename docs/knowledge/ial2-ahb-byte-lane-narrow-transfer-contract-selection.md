---
id: ial2-ahb-byte-lane-narrow-transfer-contract-selection
title: AHB byte-lane contract selection chooses new subordinate PPIF source
answers:
  - "what source did the AHB byte-lane contract select?"
  - "which task implements AHB byte-lane narrow transfers?"
  - "what are the selected AHB byte-lane HSIZE encodings?"
  - "what is the AHB byte-lane support-accounting identity?"
date: 2026-06-30
status: current
tags: [ial2, ahb, byte-lane, narrow-transfer, contract, task-tree]
evidence: docs/IAL2_AHB_BYTE_LANE_NARROW_TRANSFER_CONTRACT_SELECTION.md; docs/IAL2_AHB_BYTE_LANE_NARROW_TRANSFER_READINESS_AUDIT.md; docs/IAL2_AHB_SUBORDINATE_SOURCE_FACT_INVENTORY.md; docs/IAL2_AHB_SUBORDINATE_PPIF_BEHAVIOR.md; docs/book/src/14-feature-backlog.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.736|IAL2-FEATURE-COMPLETENESS-FRONTIER\.737|ppif/ahb_lite_subordinate_byte_lane\.ppif|intent\.ppif_ahb_lite_subordinate_byte_lane|HSIZE|byte|halfword|word' docs/IAL2_AHB_BYTE_LANE_NARROW_TRANSFER_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md MEMORY.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.736` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.737`, direct implementation of the first
bounded public AHB byte-lane/narrow-transfer subordinate source.

The selected future source is
`ppif/ahb_lite_subordinate_byte_lane.ppif`, with intent and module name
`ahb_lite_subordinate_byte_lane`. It support-accounts as
`intent.ppif_ahb_lite_subordinate_byte_lane`, coverage
`ial2_ppif_ahb_lite_subordinate_byte_lane_pipeline_cli`, and source kind
`ppif`.

The selected accepted `HSIZE` encodings are byte `3'b000`, halfword `3'b001`,
and word `3'b010`. The selected lane policy is little-endian active lanes,
narrow writes preserve inactive lanes, and narrow reads zero-fill inactive
lanes for deterministic fixture behavior.
