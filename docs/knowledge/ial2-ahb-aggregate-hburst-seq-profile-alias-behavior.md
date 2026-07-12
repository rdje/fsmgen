---
id: ial2-ahb-aggregate-hburst-seq-profile-alias-behavior
title: AHB aggregate HBURST byte-lane SEQ .ahb profile aliases are shipped
answers:
  - "do the AHB aggregate HBURST byte-lane SEQ .ahb aliases exist?"
  - "what are the support identities for the AHB aggregate HBURST SEQ aliases?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.772 ship?"
  - "which .ahb aliases mirror the aggregate HBURST SEQ PPIF sources?"
  - "what residue do the aggregate HBURST SEQ .ahb aliases remove?"
date: 2026-07-12
status: current
tags: [ial2, ahb, hburst, seq, aggregate, profile-alias, behavior]
evidence: docs/IAL2_AHB_AGGREGATE_HBURST_SEQ_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_AHB_AGGREGATE_HBURST_SEQ_ALIAS_CONTRACT_SELECTION.md; ppif/ahb_interconnect_byte_lane_hburst_seq.ahb; ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ahb; ppif/ahb_interconnect_byte_lane_hburst_seq.ppif; ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ppif; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1493-ial2-ahb-interconnect-byte-lane-hburst-seq-profile-alias.t; t/1492-ial2-ahb-interconnect-byte-lane-hburst-seq.t; README.md; ROADMAP_V2.md; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; MEMORY.md
reverify: rg -n 'intent\.ahb_profile_alias_interconnect_byte_lane_hburst_seq|intent\.ahb_profile_alias_interconnect_two_subordinate_byte_lane_hburst_seq|ahb_interconnect_byte_lane_hburst_seq\.ahb|ahb_interconnect_two_subordinate_byte_lane_hburst_seq\.ahb' perl/FSM/Support/RegressionCorpus.pm docs/IAL2_AHB_AGGREGATE_HBURST_SEQ_PROFILE_ALIAS_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.772` ships the matching bounded public
`.ahb` aliases `ppif/ahb_interconnect_byte_lane_hburst_seq.ahb` and
`ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ahb`, byte-identical
mirrors of the shipped generic aggregate HBURST-aware byte-lane `SEQ` `.ppif`
sources.

They support-account as
`intent.ahb_profile_alias_interconnect_byte_lane_hburst_seq` (coverage
`ial2_ahb_profile_alias_interconnect_byte_lane_hburst_seq_pipeline_cli`,
`composition_child_count: 3`) and
`intent.ahb_profile_alias_interconnect_two_subordinate_byte_lane_hburst_seq`
(coverage
`ial2_ahb_profile_alias_interconnect_two_subordinate_byte_lane_hburst_seq_pipeline_cli`,
`composition_child_count: 4`), both `source_kind: ial2_profile_alias`, module
`ahb_tb`.

The aliases preserve generated review artifacts, HDL entry `ahb_tb`,
`composition.byte_lane_propagation`, and `composition.seq_policy_propagation`
mode `subordinate_owned_hburst_in_word_seq_policy` (child-local
`HBURST_REGS`/`HBURST_STATUS`/`HBURST_CONTROL` fanout, `length_source: HBURST`,
supported HBURST modes `WRAP4`/`INCR4`). The shared suffix-keyed suppression
removes `ahb_aggregate_profile_alias_deferred` and
`ahb_subordinate_profile_alias_deferred` from the alias reports while the
generic `.ppif` reports keep them; no adapter code changed (data-only). Focused
coverage is `t/1493`; `t/1492` now asserts the aliases exist. BUSY-in-burst,
halfword/word burst `SEQ`, wider/indefinite bursts, broader AHB, backend
variants, AXI/APB, and VHDL remain deferred.
