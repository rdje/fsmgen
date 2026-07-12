---
id: ial2-ahb-aggregate-hburst-seq-alias-contract-selection
title: AHB aggregate HBURST SEQ follow-on selects the matching .ahb aliases
answers:
  - "what follows AHB aggregate HBURST SEQ PPIF behavior?"
  - "which task will add the AHB aggregate HBURST SEQ .ahb aliases?"
  - "do the AHB aggregate HBURST byte-lane SEQ .ahb aliases exist yet?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.771 select?"
  - "what support identities are selected for the AHB aggregate HBURST SEQ aliases?"
date: 2026-07-12
status: current
tags: [ial2, ahb, hburst, seq, aggregate, profile-alias, selector]
evidence: docs/IAL2_AHB_AGGREGATE_HBURST_SEQ_ALIAS_CONTRACT_SELECTION.md; docs/IAL2_AHB_AGGREGATE_HBURST_SEQ_BEHAVIOR.md; docs/IAL2_POST_AHB_AGGREGATE_HBURST_SEQ_PPIF_NEXT_SLICE_SELECTION.md; ppif/ahb_interconnect_byte_lane_hburst_seq.ppif; ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ppif; ppif/ahb_interconnect_byte_lane_seq.ahb; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1492-ial2-ahb-interconnect-byte-lane-hburst-seq.t; t/1489-ial2-ahb-interconnect-byte-lane-seq-profile-alias.t; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.771|IAL2-FEATURE-COMPLETENESS-FRONTIER\.772|ahb_interconnect_byte_lane_hburst_seq\.ahb|ahb_interconnect_two_subordinate_byte_lane_hburst_seq\.ahb|intent\.ahb_profile_alias_interconnect_byte_lane_hburst_seq|intent\.ahb_profile_alias_interconnect_two_subordinate_byte_lane_hburst_seq' docs/IAL2_AHB_AGGREGATE_HBURST_SEQ_ALIAS_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/book/src/16c-ial2-ahb.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.771` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.772`, direct implementation of the matching
bounded public AHB aggregate HBURST-aware byte-lane `SEQ` `.ahb` profile
aliases.

The selected future sources are
`ppif/ahb_interconnect_byte_lane_hburst_seq.ahb` and
`ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ahb`, mirroring the
shipped generic sources `ppif/ahb_interconnect_byte_lane_hburst_seq.ppif` and
`ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ppif`.

The selected aliases must support-account as
`intent.ahb_profile_alias_interconnect_byte_lane_hburst_seq` (coverage
`ial2_ahb_profile_alias_interconnect_byte_lane_hburst_seq_pipeline_cli`,
`composition_child_count: 3`) and
`intent.ahb_profile_alias_interconnect_two_subordinate_byte_lane_hburst_seq`
(coverage
`ial2_ahb_profile_alias_interconnect_two_subordinate_byte_lane_hburst_seq_pipeline_cli`,
`composition_child_count: 4`), report `source_kind: ial2_profile_alias`,
preserve HDL entry `ahb_tb`, `composition.byte_lane_propagation`, and
`composition.seq_policy_propagation` mode
`subordinate_owned_hburst_in_word_seq_policy`, and rely on the existing
suffix-keyed suppression to remove `ahb_aggregate_profile_alias_deferred` and
`ahb_subordinate_profile_alias_deferred` from the alias reports while the
generic `.ppif` reports keep them.

Reserved `.ahb` label probes confirm the shared profile-alias machinery
generalizes with no adapter change, so `.772` is data-only. BUSY-in-burst
parking, halfword/word burst `SEQ`, wider or indefinite bursts,
multi-word/register-bank progression, optional signals, broader AHB, AXI/APB,
and VHDL remain deferred. `.771` changes no behavior by itself.
