---
id: ial2-post-ahb-hburst-seq-ppif-next-slice-selection
title: AHB HBURST SEQ follow-on selects the matching .ahb alias
answers:
  - "what follows AHB HBURST SEQ PPIF behavior?"
  - "which task will add the AHB HBURST SEQ .ahb alias?"
  - "does the AHB HBURST byte-lane SEQ .ahb alias exist yet?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.765 select?"
  - "what support identity is selected for the AHB HBURST SEQ alias?"
date: 2026-06-30
status: current
tags: [ial2, ahb, hburst, seq, profile-alias, selector]
evidence: docs/IAL2_POST_AHB_HBURST_SEQ_PPIF_NEXT_SLICE_SELECTION.md; docs/IAL2_AHB_HBURST_LENGTH_WRAP_SEQ_BEHAVIOR.md; docs/IAL2_AHB_HBURST_LENGTH_WRAP_SEQ_CONTRACT_SELECTION.md; ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1490-ial2-ahb-subordinate-byte-lane-hburst-seq.t; t/1487-ial2-ahb-subordinate-byte-lane-seq-profile-alias.t; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.765|IAL2-FEATURE-COMPLETENESS-FRONTIER\.766|ahb_lite_subordinate_byte_lane_hburst_seq\.ahb|intent\.ahb_profile_alias_subordinate_byte_lane_hburst_seq|ial2_ahb_profile_alias_subordinate_byte_lane_hburst_seq_pipeline_cli' docs/IAL2_POST_AHB_HBURST_SEQ_PPIF_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.765` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.766`, direct implementation of the matching
bounded public AHB HBURST-aware byte-lane `SEQ` subordinate `.ahb` profile
alias.

The selected future source is
`ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ahb`, mirroring the shipped
generic source `ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif`.

The selected alias must support-account as
`intent.ahb_profile_alias_subordinate_byte_lane_hburst_seq`, use coverage
`ial2_ahb_profile_alias_subordinate_byte_lane_hburst_seq_pipeline_cli`, report
`source_kind: ial2_profile_alias`, preserve generated
`ahb_lite_subordinate_byte_lane_hburst_seq.isf` /
`ahb_lite_subordinate_byte_lane_hburst_seq.fsm`, preserve
`bindings.bus.burst` and `transfer.seq_policy.mode =
hburst_in_word_progressive`, and remove `.ahb alias exposure` from the alias
report's remaining `ahb_burst_seq_support_deferred` detail.

Aggregate HBURST propagation, BUSY-in-burst parking, halfword/word burst
`SEQ`, wider or indefinite bursts, multi-word/register-bank progression,
optional signals, broader AHB, AXI/APB, and VHDL remain deferred.
