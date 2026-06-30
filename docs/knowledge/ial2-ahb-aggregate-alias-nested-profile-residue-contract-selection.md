---
id: ial2-ahb-aggregate-alias-nested-profile-residue-contract-selection
title: AHB aggregate .ahb aliases select nested endpoint profile-residue cleanup
answers:
  - "what AHB aggregate alias nested residue cleanup was selected?"
  - "which AHB aggregate .ahb reports should remove endpoint profile alias residue?"
  - "do generic AHB aggregate PPIF reports keep child profile alias residue?"
  - "is a new nested child provenance field needed for AHB aggregate aliases?"
  - "which task implements aggregate AHB alias nested profile residue cleanup?"
date: 2026-06-30
status: current
tags: [ial2, ahb, interconnect, aggregate, profile-alias, residue, contract]
evidence: docs/IAL2_AHB_AGGREGATE_ALIAS_NESTED_PROFILE_RESIDUE_CONTRACT_SELECTION.md; docs/IAL2_POST_AHB_AGGREGATE_BYTE_LANE_ALIAS_NEXT_SLICE_SELECTION.md; docs/IAL2_AHB_AGGREGATE_BYTE_LANE_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_AHB_INTERCONNECT_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_AHB_TWO_SUBORDINATE_PROFILE_ALIAS_BEHAVIOR.md; perl/FSM/Adapter/IAL2/PPIF.pm; t/1479-ial2-ahb-interconnect-profile-alias.t; t/1481-ial2-ahb-interconnect-two-subordinate-profile-alias.t; t/1485-ial2-ahb-interconnect-byte-lane-profile-alias.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.747|IAL2-FEATURE-COMPLETENESS-FRONTIER\.748|ahb_profile_alias_deferred|ahb_subordinate_profile_alias_deferred|ppif/ahb_interconnect_byte_lane\.ahb|ppif/ahb_interconnect_two_subordinate_byte_lane\.ahb' docs/IAL2_AHB_AGGREGATE_ALIAS_NESTED_PROFILE_RESIDUE_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md MEMORY.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.747` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.748`, direct implementation of the
bounded report cleanup for shipped aggregate AHB `.ahb` aliases.

The selected cleanup removes `ahb_aggregate_profile_alias_deferred`,
`ahb_profile_alias_deferred`, and `ahb_subordinate_profile_alias_deferred`
recursively from aggregate `.ahb` reports only. It covers the word-only and
byte-lane one-subordinate and two-subordinate aggregate `.ahb` aliases.

Generic aggregate `.ppif` reports must keep those source-surface residues. No
new nested child provenance fields are selected because top-level source
identity and support accounting already identify the aggregate profile-alias
surface.
