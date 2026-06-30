---
id: ial2-ahb-hburst-length-wrap-seq-contract-selection
title: AHB HBURST length/wrap SEQ contract selects endpoint implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.763 select?"
  - "what is the first AHB HBURST-aware byte-lane SEQ source?"
  - "which HBURST modes are selected for first AHB subordinate SEQ support?"
  - "what implements AHB HBURST length wrap SEQ after the readiness audit?"
date: 2026-06-30
status: current
tags: [ial2, ahb, hburst, seq, contract-selection]
evidence: docs/IAL2_AHB_HBURST_LENGTH_WRAP_SEQ_CONTRACT_SELECTION.md; docs/IAL2_AHB_HBURST_LENGTH_WRAP_SEQ_READINESS_AUDIT.md; docs/IAL2_AHB_BURST_SEQ_CONTRACT_SELECTION.md; docs/IAL2_AHB_BYTE_LANE_SEQ_BEHAVIOR.md; ppif/ahb_lite_subordinate_byte_lane_seq.ppif; ppif/ahb_requester.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; perl/FSM/Support/RegressionCorpus.pm; docs/book/src/16c-ial2-ahb.md; README.md; ROADMAP_V2.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md
reverify: rg -n "IAL2-FEATURE-COMPLETENESS-FRONTIER\\.763|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.764|ahb_lite_subordinate_byte_lane_hburst_seq|hburst-in-word-progressive|supported_hburst_modes|WRAP4, INCR4" docs/IAL2_AHB_HBURST_LENGTH_WRAP_SEQ_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/book/src/16c-ial2-ahb.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.763` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.764`, direct implementation of
`ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif`.

The selected source adds subordinate bus syntax `(burst HBURST width 3)` and
transfer syntax `(seq-policy hburst-in-word-progressive)`, support-accounted
as `intent.ppif_ahb_lite_subordinate_byte_lane_hburst_seq` with coverage
`ial2_ppif_ahb_lite_subordinate_byte_lane_hburst_seq_pipeline_cli`.

The first supported HBURST `SEQ` modes are byte-only `WRAP4` and `INCR4`
inside one 32-bit register word. `SINGLE` remains non-SEQ only; `INCR`,
`WRAP8`, `INCR8`, `WRAP16`, `INCR16`, halfword/word burst `SEQ`,
BUSY-in-burst parking, aggregate propagation, matching `.ahb` alias exposure,
broader AHB, backend variants, AXI/APB, and VHDL remain deferred.
