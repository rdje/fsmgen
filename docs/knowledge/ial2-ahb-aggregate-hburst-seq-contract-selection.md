---
id: ial2-ahb-aggregate-hburst-seq-contract-selection
title: AHB aggregate HBURST SEQ contract selection
answers:
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.769 select?"
  - "which sources are selected for aggregate AHB HBURST SEQ propagation?"
  - "what support IDs are selected for aggregate AHB HBURST SEQ PPIF?"
  - "how should aggregate AHB HBURST be forwarded to child subordinates?"
  - "which task implements aggregate AHB HBURST SEQ PPIF?"
date: 2026-06-30
status: current
tags: [ial2, ahb, hburst, seq, aggregate, contract]
evidence: docs/IAL2_AHB_AGGREGATE_HBURST_SEQ_CONTRACT_SELECTION.md; docs/IAL2_AHB_AGGREGATE_HBURST_SEQ_READINESS_AUDIT.md; ppif/ahb_interconnect_byte_lane_seq.ppif; ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ppif; ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif; docs/IAL2_AHB_HBURST_LENGTH_WRAP_SEQ_BEHAVIOR.md; docs/IAL2_AHB_AGGREGATE_BYTE_LANE_SEQ_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/16c-ial2-ahb.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.769|IAL2-FEATURE-COMPLETENESS-FRONTIER\.770|ahb_interconnect_byte_lane_hburst_seq|ahb_interconnect_two_subordinate_byte_lane_hburst_seq|intent\.ppif_ahb_interconnect_byte_lane_hburst_seq|intent\.ppif_ahb_interconnect_two_subordinate_byte_lane_hburst_seq|HBURST_REGS|HBURST_STATUS|subordinate_owned_hburst_in_word_seq_policy' docs/IAL2_AHB_AGGREGATE_HBURST_SEQ_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/16c-ial2-ahb.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.769` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.770`, direct implementation of the
combined bounded generic `.ppif` AHB aggregate HBURST-aware byte-lane `SEQ`
propagation family.

The selected public sources are
`ppif/ahb_interconnect_byte_lane_hburst_seq.ppif` and
`ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ppif`.

The selected support IDs are
`intent.ppif_ahb_interconnect_byte_lane_hburst_seq` and
`intent.ppif_ahb_interconnect_two_subordinate_byte_lane_hburst_seq`, with
coverage keys `ial2_ppif_ahb_interconnect_byte_lane_hburst_seq_pipeline_cli`
and
`ial2_ppif_ahb_interconnect_two_subordinate_byte_lane_hburst_seq_pipeline_cli`.

The selected child HBURST fanout is direct requester/global fanout from
`HBURST` to child-local `HBURST_REGS`, `HBURST_STATUS`, and
`HBURST_CONTROL`. The aggregate report reuses
`composition.seq_policy_propagation` with mode
`subordinate_owned_hburst_in_word_seq_policy`, request-forwarding `burst`, and
child `bindings.bus.burst` plus `transfer.seq_policy` propagation.

Matching aggregate `.ahb` aliases, BUSY-in-burst parking, halfword/word burst
`SEQ`, wider or indefinite bursts, multi-word/register-bank progression,
broader AHB, backend variants, AXI/APB, and VHDL remain deferred.
