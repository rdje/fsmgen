---
id: ial2-post-ahb-aggregate-byte-lane-ppif-next-slice-selection
title: Post AHB aggregate byte-lane PPIF selector chooses matching alias implementation
answers:
  - "what follows AHB aggregate byte-lane PPIF behavior?"
  - "which task owns AHB aggregate byte-lane .ahb aliases?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.744 select?"
  - "are AHB aggregate byte-lane .ahb aliases selected?"
  - "what support identities were selected for AHB aggregate byte-lane aliases?"
date: 2026-06-30
status: current
tags: [ial2, ahb, interconnect, aggregate, byte-lane, profile-alias, task-tree]
evidence: docs/IAL2_POST_AHB_AGGREGATE_BYTE_LANE_PPIF_NEXT_SLICE_SELECTION.md; docs/IAL2_AHB_AGGREGATE_BYTE_LANE_PROPAGATION_BEHAVIOR.md; docs/IAL2_AHB_AGGREGATE_BYTE_LANE_PROPAGATION_CONTRACT_SELECTION.md; docs/IAL2_AHB_AGGREGATE_BYTE_LANE_PROPAGATION_READINESS_AUDIT.md; ppif/ahb_interconnect_byte_lane.ppif; ppif/ahb_interconnect_two_subordinate_byte_lane.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1484-ial2-ahb-interconnect-byte-lane.t; docs/book/src/16c-ial2-ahb.md; docs/book/src/16-ial2-protocol-platform-intent.md; docs/book/src/14-feature-backlog.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.744|IAL2-FEATURE-COMPLETENESS-FRONTIER\.745|ahb_interconnect_byte_lane\.ahb|intent\.ahb_profile_alias_interconnect_byte_lane|intent\.ahb_profile_alias_interconnect_two_subordinate_byte_lane' docs/IAL2_POST_AHB_AGGREGATE_BYTE_LANE_PPIF_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md MEMORY.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/book/src/16c-ial2-ahb.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.744` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.745`, direct implementation of the
matching bounded public AHB aggregate byte-lane `.ahb` profile aliases:
`ppif/ahb_interconnect_byte_lane.ahb` and
`ppif/ahb_interconnect_two_subordinate_byte_lane.ahb`.

Selector probes parsed the shipped generic aggregate byte-lane `.ppif` source
text with `.ahb` labels. Current code accepted both selected aggregate
topologies, preserved `composition.byte_lane_propagation`, preserved child
`narrow_transfer_policy`, and removed only
`ahb_aggregate_profile_alias_deferred` from the alias-labeled reports.

`.745` must support-account the aliases as
`intent.ahb_profile_alias_interconnect_byte_lane` and
`intent.ahb_profile_alias_interconnect_two_subordinate_byte_lane`, both with
source kind `ial2_profile_alias`, coverage keys
`ial2_ahb_profile_alias_interconnect_byte_lane_pipeline_cli` and
`ial2_ahb_profile_alias_interconnect_two_subordinate_byte_lane_pipeline_cli`,
HDL module `ahb_tb`, and composition child counts 3 and 4.
