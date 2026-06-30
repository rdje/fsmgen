---
id: ial2-ahb-aggregate-byte-lane-propagation-contract-selection
title: AHB aggregate byte-lane contract selects two generic PPIF sources
answers:
  - "what AHB aggregate byte-lane contract was selected?"
  - "which source paths implement aggregate byte-lane propagation?"
  - "what report block should aggregate byte-lane sources expose?"
  - "which task implements aggregate byte-lane generic sources?"
  - "are AHB aggregate byte-lane .ahb aliases selected now?"
date: 2026-06-30
status: current
tags: [ial2, ahb, interconnect, aggregate, byte-lane, narrow-transfer, contract]
evidence: docs/IAL2_AHB_AGGREGATE_BYTE_LANE_PROPAGATION_CONTRACT_SELECTION.md; docs/IAL2_AHB_AGGREGATE_BYTE_LANE_PROPAGATION_READINESS_AUDIT.md; docs/IAL2_AHB_BYTE_LANE_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_AHB_BYTE_LANE_NARROW_TRANSFER_BEHAVIOR.md; docs/IAL2_AHB_INTERCONNECT_DECODE_BEHAVIOR.md; docs/IAL2_AHB_TWO_SUBORDINATE_BEHAVIOR.md; ppif/ahb_lite_subordinate_byte_lane.ppif; ppif/ahb_lite_subordinate_byte_lane.ahb; ppif/ahb_interconnect.ppif; ppif/ahb_interconnect_two_subordinate.ppif; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.742|IAL2-FEATURE-COMPLETENESS-FRONTIER\.743|ppif/ahb_interconnect_byte_lane\.ppif|ppif/ahb_interconnect_two_subordinate_byte_lane\.ppif|composition\.byte_lane_propagation|intent\.ppif_ahb_interconnect_byte_lane|t/1484-ial2-ahb-interconnect-byte-lane\.t' docs/IAL2_AHB_AGGREGATE_BYTE_LANE_PROPAGATION_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md MEMORY.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.742` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.743`, direct implementation of the
combined bounded generic `.ppif` AHB aggregate byte-lane and narrow-transfer
propagation family.

The selected public sources are `ppif/ahb_interconnect_byte_lane.ppif` and
`ppif/ahb_interconnect_two_subordinate_byte_lane.ppif`. The selected aggregate
report addition is `composition.byte_lane_propagation`, with child
`narrow_transfer_policy` propagation for embedded byte-lane subordinates.

Matching `.ahb` aliases are not part of `.743`; they remain future follow-on
work after the generic `.ppif` behavior ships.
