---
id: ial2-post-ahb-byte-lane-seq-next-slice-selection
title: AHB byte-lane SEQ follow-on selects the .ahb alias
answers:
  - "what follows AHB byte-lane SEQ?"
  - "what is the next AHB SEQ follow-on?"
  - "which task will add the AHB byte-lane SEQ .ahb alias?"
  - "does the AHB byte-lane SEQ .ahb alias exist yet?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.753 select?"
date: 2026-06-30
status: current
tags: [ial2, ahb, burst, seq, profile-alias, selector]
evidence: docs/IAL2_POST_AHB_BYTE_LANE_SEQ_NEXT_SLICE_SELECTION.md; docs/IAL2_AHB_BYTE_LANE_SEQ_BEHAVIOR.md; ppif/ahb_lite_subordinate_byte_lane_seq.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1486-ial2-ahb-subordinate-byte-lane-seq.t; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.753|IAL2-FEATURE-COMPLETENESS-FRONTIER\.754|ahb_lite_subordinate_byte_lane_seq\.ahb|intent\.ahb_profile_alias_subordinate_byte_lane_seq|ial2_ahb_profile_alias_subordinate_byte_lane_seq_pipeline_cli' docs/IAL2_POST_AHB_BYTE_LANE_SEQ_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.753` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.754`, direct implementation of the matching
bounded public AHB byte-lane in-word `SEQ` subordinate `.ahb` profile alias.

The selected future source is
`ppif/ahb_lite_subordinate_byte_lane_seq.ahb`, mirroring the shipped generic
source `ppif/ahb_lite_subordinate_byte_lane_seq.ppif`.

The selected alias must support-account as
`intent.ahb_profile_alias_subordinate_byte_lane_seq`, use coverage
`ial2_ahb_profile_alias_subordinate_byte_lane_seq_pipeline_cli`, report
`source_kind: ial2_profile_alias`, preserve generated
`ahb_lite_subordinate_byte_lane_seq.isf` /
`ahb_lite_subordinate_byte_lane_seq.fsm`, preserve `transfer.seq_policy`, and
remove `.ahb alias exposure` from the alias report's remaining
`ahb_burst_seq_support_deferred` detail.

Aggregate `SEQ` propagation, HBURST length/wrap semantics, BUSY-in-burst
parking, multi-word/register-bank progression, optional signals, broader AHB,
AXI/APB, and VHDL remain deferred.
