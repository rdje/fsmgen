---
id: ial2-ahb-aggregate-byte-lane-seq-contract-selection
title: AHB aggregate byte-lane SEQ contract selects generic PPIF implementation
answers:
  - "what is the contract for AHB aggregate byte-lane SEQ propagation?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.757 select?"
  - "which AHB aggregate SEQ sources will be implemented?"
  - "does .757 add aggregate AHB SEQ behavior?"
date: 2026-06-30
status: current
tags: [ial2, ahb, contract, aggregate, seq, byte-lane]
evidence: docs/IAL2_AHB_AGGREGATE_BYTE_LANE_SEQ_CONTRACT_SELECTION.md; docs/IAL2_AHB_AGGREGATE_BYTE_LANE_SEQ_READINESS_AUDIT.md; docs/IAL2_AHB_BYTE_LANE_SEQ_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_AHB_AGGREGATE_BYTE_LANE_PROPAGATION_BEHAVIOR.md; ppif/ahb_interconnect_byte_lane.ppif; ppif/ahb_interconnect_two_subordinate_byte_lane.ppif; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.757|IAL2-FEATURE-COMPLETENESS-FRONTIER\.758|ppif/ahb_interconnect_byte_lane_seq\.ppif|ppif/ahb_interconnect_two_subordinate_byte_lane_seq\.ppif|composition\.seq_policy_propagation|intent\.ppif_ahb_interconnect_byte_lane_seq' docs/IAL2_AHB_AGGREGATE_BYTE_LANE_SEQ_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.757` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.758`, direct implementation of the
combined bounded generic `.ppif` AHB aggregate byte-lane in-word `SEQ`
propagation family.

The selected sources are `ppif/ahb_interconnect_byte_lane_seq.ppif` and
`ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ppif`. Reports must
preserve `composition.byte_lane_propagation` and add
`composition.seq_policy_propagation`, with generated child reports carrying
both `narrow_transfer_policy` and `transfer.seq_policy`.

`.757` changes no parser, generator, source, support-accounting, report,
generated artifact, HDL, or runtime behavior. Matching aggregate `.ahb` aliases
remain deferred after the generic `.ppif` implementation.
