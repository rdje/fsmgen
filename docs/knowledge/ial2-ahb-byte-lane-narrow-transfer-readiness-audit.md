---
id: ial2-ahb-byte-lane-narrow-transfer-readiness-audit
title: AHB byte-lane readiness selects public subordinate contract selection
answers:
  - "what did the AHB byte-lane readiness audit select?"
  - "which task owns AHB narrow-transfer contract selection?"
  - "what are the first AHB byte-lane contract expectations?"
  - "does AHB byte-lane readiness change existing word-only subordinate sources?"
date: 2026-06-30
status: current
tags: [ial2, ahb, byte-lane, narrow-transfer, readiness, task-tree]
evidence: docs/IAL2_AHB_BYTE_LANE_NARROW_TRANSFER_READINESS_AUDIT.md; docs/IAL2_AHB_REMAINING_RESIDUE_READINESS_AUDIT.md; docs/IAL2_AHB_SUBORDINATE_SOURCE_FACT_INVENTORY.md; docs/IAL2_AHB_SUBORDINATE_PPIF_BEHAVIOR.md; ppif/ahb_lite_subordinate.ppif; ppif/ahb_lite_subordinate.ahb; fsm/ahb_lite_subordinate.fsm; docs/book/src/14-feature-backlog.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: ./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate.ppif && ./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate.ahb && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.735|IAL2-FEATURE-COMPLETENESS-FRONTIER\.736|HSIZE|HADDR|byte lane|narrow-transfer|word-only' docs/IAL2_AHB_BYTE_LANE_NARROW_TRANSFER_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md MEMORY.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.735` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.736`, a no-behavior public contract
selection for the first bounded AHB byte-lane and narrow-transfer subordinate
source.

The audit finds no lower-layer generated-IAL1/IAL0 substrate, source-fact,
report-schema, or support-accounting prerequisite before contract selection.
The first behavior should target a new generic subordinate `.ppif` source,
likely `ppif/ahb_lite_subordinate_byte_lane.ppif`, while the existing
word-only `ppif/ahb_lite_subordinate.ppif` and `.ahb` alias stay unchanged.

The selected contract questions for `.736` include byte/halfword/word `HSIZE`
encodings, `HADDR` low-bit lane selection, narrow write byte preservation,
deterministic narrow read projection, unaligned/crossing ERROR diagnostics,
report/support-accounting identity, validation gates, residue movement, and
continued VHDL deferral.
