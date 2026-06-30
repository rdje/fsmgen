---
id: ial2-post-ahb-aggregate-hburst-seq-ppif-next-slice-selection
title: AHB aggregate HBURST SEQ PPIF follow-on selects aggregate HBURST aliases
answers:
  - "what follows AHB aggregate HBURST SEQ PPIF?"
  - "which task selects AHB aggregate HBURST SEQ .ahb aliases?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.770 select next?"
date: 2026-06-30
status: current
tags: [ial2, ahb, hburst, seq, aggregate, profile-alias, selector]
evidence: docs/IAL2_POST_AHB_AGGREGATE_HBURST_SEQ_PPIF_NEXT_SLICE_SELECTION.md; docs/IAL2_AHB_AGGREGATE_HBURST_SEQ_BEHAVIOR.md; ppif/ahb_interconnect_byte_lane_hburst_seq.ppif; ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ppif; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1492-ial2-ahb-interconnect-byte-lane-hburst-seq.t; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.770|IAL2-FEATURE-COMPLETENESS-FRONTIER\.771|ahb_interconnect_byte_lane_hburst_seq\.ahb|ahb_interconnect_two_subordinate_byte_lane_hburst_seq\.ahb|aggregate HBURST-aware byte-lane' docs/IAL2_POST_AHB_AGGREGATE_HBURST_SEQ_PPIF_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/book/src/16c-ial2-ahb.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.770` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.771`, a no-behavior public contract
selection for matching bounded public AHB aggregate HBURST-aware byte-lane
`SEQ` `.ahb` profile aliases.

The candidate aliases are `ppif/ahb_interconnect_byte_lane_hburst_seq.ahb` and
`ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ahb`, mirroring
the shipped generic sources `ppif/ahb_interconnect_byte_lane_hburst_seq.ppif`
and `ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ppif`.

`.771` must pin the exact alias contract, support identities, coverage keys,
source kind, generated artifacts, alias-only residue cleanup, focused tests,
and preservation matrix before implementation. It changes no behavior by
itself.
