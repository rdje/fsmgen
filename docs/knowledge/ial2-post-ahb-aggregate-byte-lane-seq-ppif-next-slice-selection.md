---
id: ial2-post-ahb-aggregate-byte-lane-seq-ppif-next-slice-selection
title: AHB aggregate byte-lane SEQ PPIF follow-on selects aggregate SEQ aliases
answers:
  - "what follows AHB aggregate byte-lane SEQ PPIF?"
  - "which task will add AHB aggregate byte-lane SEQ .ahb aliases?"
  - "does ppif/ahb_interconnect_byte_lane_seq.ahb exist yet?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.759 select?"
date: 2026-06-30
status: current
tags: [ial2, ahb, interconnect, aggregate, byte-lane, seq, profile-alias, selector]
evidence: docs/IAL2_POST_AHB_AGGREGATE_BYTE_LANE_SEQ_PPIF_NEXT_SLICE_SELECTION.md; docs/IAL2_AHB_AGGREGATE_BYTE_LANE_SEQ_BEHAVIOR.md; docs/IAL2_AHB_AGGREGATE_BYTE_LANE_SEQ_CONTRACT_SELECTION.md; docs/IAL2_AHB_AGGREGATE_BYTE_LANE_SEQ_READINESS_AUDIT.md; ppif/ahb_interconnect_byte_lane_seq.ppif; ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1488-ial2-ahb-interconnect-byte-lane-seq.t; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.759|IAL2-FEATURE-COMPLETENESS-FRONTIER\.760|ahb_interconnect_byte_lane_seq\.ahb|ahb_interconnect_two_subordinate_byte_lane_seq\.ahb|intent\.ahb_profile_alias_interconnect_byte_lane_seq|ial2_ahb_profile_alias_interconnect_two_subordinate_byte_lane_seq_pipeline_cli' docs/IAL2_POST_AHB_AGGREGATE_BYTE_LANE_SEQ_PPIF_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/book/src/16c-ial2-ahb.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.759` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.760`, direct implementation of the matching
bounded public AHB aggregate byte-lane in-word `SEQ` `.ahb` profile aliases.

The selected future sources are
`ppif/ahb_interconnect_byte_lane_seq.ahb` and
`ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ahb`, mirroring the
shipped generic sources `ppif/ahb_interconnect_byte_lane_seq.ppif` and
`ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ppif`.

The selected aliases must support-account as
`intent.ahb_profile_alias_interconnect_byte_lane_seq` and
`intent.ahb_profile_alias_interconnect_two_subordinate_byte_lane_seq`, use
coverage keys `ial2_ahb_profile_alias_interconnect_byte_lane_seq_pipeline_cli`
and
`ial2_ahb_profile_alias_interconnect_two_subordinate_byte_lane_seq_pipeline_cli`,
report `source_kind: ial2_profile_alias`, preserve
`composition.byte_lane_propagation`, preserve
`composition.seq_policy_propagation`, and remove alias-only `.ahb alias
exposure` wording from embedded byte-lane `SEQ` child residue while generic
`.ppif` reports keep source-surface alias residue.

HBURST length/wrap semantics, BUSY-in-burst handling,
multi-word/register-bank progression, optional signals, broader AHB,
AXI/APB, direct backend, verification-output, backend-language variants, and
VHDL remain deferred.
