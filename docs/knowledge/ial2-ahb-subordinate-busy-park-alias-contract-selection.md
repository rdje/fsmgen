---
id: ial2-ahb-subordinate-busy-park-alias-contract-selection
title: AHB subordinate BUSY-park follow-on selects the matching .ahb alias
answers:
  - "what follows the AHB subordinate BUSY-park endpoint .ppif behavior?"
  - "which task will add the AHB subordinate BUSY-park .ahb alias?"
  - "does the AHB subordinate BUSY-park .ahb alias exist yet?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.777 select?"
  - "what support identity is selected for the AHB BUSY-park .ahb alias?"
date: 2026-07-12
status: current
tags: [ial2, ahb, hburst, seq, busy, parking, profile-alias, selector]
evidence: docs/IAL2_AHB_SUBORDINATE_BUSY_PARK_ALIAS_CONTRACT_SELECTION.md; docs/IAL2_AHB_SUBORDINATE_BUSY_PARK_CONTRACT_SELECTION.md; ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif; ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ahb; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1491-ial2-ahb-subordinate-byte-lane-hburst-seq-profile-alias.t; t/1494-ial2-ahb-subordinate-byte-lane-hburst-seq-busy-park.t; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.777|IAL2-FEATURE-COMPLETENESS-FRONTIER\.778|ahb_lite_subordinate_byte_lane_hburst_seq_busy_park\.ahb|intent\.ahb_profile_alias_subordinate_byte_lane_hburst_seq_busy_park|ial2_ahb_profile_alias_subordinate_byte_lane_hburst_seq_busy_park_pipeline_cli' docs/IAL2_AHB_SUBORDINATE_BUSY_PARK_ALIAS_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/book/src/16c-ial2-ahb.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.777` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.778`, direct implementation of the matching
bounded public AHB subordinate BUSY-in-burst parking `.ahb` profile alias.

The selected future source is
`ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ahb`, mirroring the
shipped generic BUSY-park source
`ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif`.

The selected alias must support-account as
`intent.ahb_profile_alias_subordinate_byte_lane_hburst_seq_busy_park` (coverage
`ial2_ahb_profile_alias_subordinate_byte_lane_hburst_seq_busy_park_pipeline_cli`,
`source_kind: ial2_profile_alias`, `expected_module_name:
ahb_lite_subordinate_byte_lane_hburst_seq_busy_park`), preserve generated
`ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.isf`/`.fsm` review
artifacts and the HDL module, preserve `transfer.seq_policy.mode =
hburst_in_word_progressive` with `parks_on = [busy]` and `clears_on = [reset,
idle, error, new_nonseq, final_beat]`, and rely on the existing suffix-keyed
suppression to remove `ahb_subordinate_profile_alias_deferred` and the `.ahb
alias exposure` residue wording from the alias report while the generic `.ppif`
report keeps them.

A reserved `.ahb` label CLI probe (a scratchpad copy of the BUSY-park source)
strict-checks, preserves the `parks_on`/`clears_on` shape, and already drops the
endpoint profile-alias residue with no adapter change, so `.778` is data-only:
add the alias fixture, its `RegressionCorpus` entry, focused
`t/1495-ial2-ahb-subordinate-byte-lane-hburst-seq-busy-park-profile-alias.t`,
the `t/248` bump (`292 → 293` protocol / `333 → 334` total) and `t/297`
manifest, and docs. Aggregate BUSY-parking, requester-side BUSY insertion,
halfword/word burst `SEQ`, wider or indefinite bursts, optional signals, broader
AHB, AXI/APB, and VHDL remain deferred. `.777` changes no behavior by itself.
