---
id: ial2-ahb-byte-lane-seq-profile-alias-behavior
title: AHB byte-lane in-word SEQ .ahb alias is shipped
answers:
  - "does AHB byte-lane SEQ have an .ahb alias?"
  - "what is ppif/ahb_lite_subordinate_byte_lane_seq.ahb?"
  - "how is AHB byte-lane SEQ profile alias support-accounted?"
  - "does the AHB byte-lane SEQ alias keep .ahb alias exposure residue?"
date: 2026-06-30
status: current
tags: [ial2, ahb, alias, burst, seq, behavior, byte-lane]
evidence: docs/IAL2_AHB_BYTE_LANE_SEQ_PROFILE_ALIAS_BEHAVIOR.md; ppif/ahb_lite_subordinate_byte_lane_seq.ahb; ppif/ahb_lite_subordinate_byte_lane_seq.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1487-ial2-ahb-subordinate-byte-lane-seq-profile-alias.t; docs/book/src/16c-ial2-ahb.md; README.md; ROADMAP_V2.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; MEMORY.md
reverify: ./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_lite_subordinate_byte_lane_seq.ahb
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.754` ships
`ppif/ahb_lite_subordinate_byte_lane_seq.ahb`, the matching AHB profile alias
for `ppif/ahb_lite_subordinate_byte_lane_seq.ppif`.

The alias support-accounts as
`intent.ahb_profile_alias_subordinate_byte_lane_seq`, uses
`source_kind: ial2_profile_alias`, lowers through
`ahb_lite_subordinate_byte_lane_seq.isf` and
`ahb_lite_subordinate_byte_lane_seq.fsm`, and emits HDL module
`ahb_lite_subordinate_byte_lane_seq`.

The alias preserves `narrow_transfer_policy` and structured
`transfer.seq_policy`. Its report removes endpoint profile-alias residue and
no longer names `.ahb alias exposure` in the remaining
`ahb_burst_seq_support_deferred` detail. The generic `.ppif` source still keeps
that source-surface alias residue.
