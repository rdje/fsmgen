---
id: ial2-ahb-hburst-length-wrap-seq-profile-alias-behavior
title: AHB HBURST byte-lane SEQ .ahb alias is shipped
answers:
  - "does AHB HBURST byte-lane SEQ have an .ahb alias?"
  - "what is ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ahb?"
  - "how is AHB HBURST SEQ profile alias support-accounted?"
  - "does the AHB HBURST SEQ alias keep .ahb alias exposure residue?"
date: 2026-06-30
status: current
tags: [ial2, ahb, hburst, alias, seq, behavior, byte-lane]
evidence: docs/IAL2_AHB_HBURST_LENGTH_WRAP_SEQ_PROFILE_ALIAS_BEHAVIOR.md; ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ahb; ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1491-ial2-ahb-subordinate-byte-lane-hburst-seq-profile-alias.t; docs/book/src/16c-ial2-ahb.md; README.md; ROADMAP_V2.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; MEMORY.md
reverify: ./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ahb
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.766` ships
`ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ahb`, the matching AHB profile
alias for `ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif`.

The alias support-accounts as
`intent.ahb_profile_alias_subordinate_byte_lane_hburst_seq`, uses
`source_kind: ial2_profile_alias`, lowers through
`ahb_lite_subordinate_byte_lane_hburst_seq.isf` and
`ahb_lite_subordinate_byte_lane_hburst_seq.fsm`, and emits HDL module
`ahb_lite_subordinate_byte_lane_hburst_seq`.

The alias preserves `bindings.bus.burst`, `transfer.seq_policy.mode =
hburst_in_word_progressive`, byte-only `WRAP4`/`INCR4` support metadata, and
the selected byte-lane policy. Its report removes endpoint profile-alias
residue and no longer names `.ahb alias exposure` in the remaining
`ahb_burst_seq_support_deferred` detail. The generic `.ppif` source still
keeps that source-surface alias residue.
