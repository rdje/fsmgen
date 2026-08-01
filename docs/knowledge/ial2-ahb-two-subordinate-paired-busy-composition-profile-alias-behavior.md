---
id: ial2-ahb-two-subordinate-paired-busy-composition-profile-alias-behavior
title: The two-subordinate paired AHB BUSY composition ships through a matching .ahb alias
answers:
  - "does FSMGen ship a two-subordinate paired AHB BUSY .ahb alias?"
  - "are the two-subordinate paired AHB BUSY .ppif and .ahb separate generators?"
  - "what does the two-subordinate paired AHB BUSY .ahb alias generate?"
  - "what support id covers the two-subordinate paired AHB BUSY alias?"
  - "which test proves two-subordinate paired AHB BUSY alias parity?"
  - "what shipped in IAL2-FEATURE-COMPLETENESS-FRONTIER.803?"
date: 2026-07-23
status: current
tags: [ial2, ahb, requester, subordinate, interconnect, busy, composition, profile-alias, behavior]
evidence: >-
  docs/IAL2_AHB_TWO_SUBORDINATE_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_AHB_TWO_SUBORDINATE_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_CONTRACT_SELECTION.md; docs/IAL2_AHB_TWO_SUBORDINATE_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md; ppif/ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park.ppif; ppif/ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park.ahb; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1515-ial2-ahb-two-subordinate-paired-busy-composition.t; t/1516-ial2-ahb-two-subordinate-paired-busy-composition-profile-alias.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/book/src/16c-ial2-ahb.md; docs/book/src/14-feature-backlog.md;
  docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
reverify: cmp ppif/ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park.ppif ppif/ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park.ahb && prove -Iperl t/1516-ial2-ahb-two-subordinate-paired-busy-composition-profile-alias.t t/1515-ial2-ahb-two-subordinate-paired-busy-composition.t
---

FSMGen ships
`ppif/ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park.ahb`
as a byte-identical profile-alias mirror of the generic `.ppif` source. They
are two public IAL2 entrypoints into the same requester/status/control/
interconnect/top generator path, not separate generators.

The alias support id is
`intent.ahb_profile_alias_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park`,
coverage is
`ial2_ahb_profile_alias_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park_pipeline_cli`,
module `ahb_tb`, child count 4, semantic root `top`. Accounting is 314 protocol
and 355 supported-smoke/strict entries.

The alias preserves four IAL1/five IAL0 artifacts, requester-child
`busy_insertion`, both child/propagated `parks_on=[busy]`, status/control
windows, and t/1515's `44332211`/`88776655` runtime result. Existing suffix
handling removes only aggregate/requester/both-subordinate alias residue and
alias-exposure wording. t/1516 proves parity, public surfaces, diagnostics,
and clean `--verify-hdl`.
