---
id: ial2-ahb-subordinate-busy-park-profile-alias-behavior
title: AHB subordinate BUSY-park .ahb profile alias is shipped
answers:
  - "does the AHB subordinate BUSY-park .ahb alias exist?"
  - "what is the support identity of the AHB BUSY-park .ahb alias?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.778 ship?"
  - "which coverage key covers the AHB BUSY-park .ahb alias?"
  - "does the AHB BUSY-park .ahb alias preserve parks_on/clears_on?"
date: 2026-07-12
status: current
tags: [ial2, ahb, hburst, seq, busy, parking, profile-alias, behavior]
evidence: docs/IAL2_AHB_SUBORDINATE_BUSY_PARK_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_AHB_SUBORDINATE_BUSY_PARK_ALIAS_CONTRACT_SELECTION.md; ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ahb; ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1495-ial2-ahb-subordinate-byte-lane-hburst-seq-busy-park-profile-alias.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; MEMORY.md
reverify: rg -n 'ahb_lite_subordinate_byte_lane_hburst_seq_busy_park\.ahb|intent\.ahb_profile_alias_subordinate_byte_lane_hburst_seq_busy_park|ial2_ahb_profile_alias_subordinate_byte_lane_hburst_seq_busy_park_pipeline_cli' ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ahb perl/FSM/Support/RegressionCorpus.pm perl/FSM/Support/LanguageSurfaceSection.pm t/1495-ial2-ahb-subordinate-byte-lane-hburst-seq-busy-park-profile-alias.t docs/IAL2_AHB_SUBORDINATE_BUSY_PARK_PROFILE_ALIAS_BEHAVIOR.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.778` ships the matching bounded public AHB
profile alias `ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ahb`, a
byte-identical mirror of the shipped generic BUSY-park source
`ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif`.

The alias support-accounts as
`intent.ahb_profile_alias_subordinate_byte_lane_hburst_seq_busy_park` with
coverage `ial2_ahb_profile_alias_subordinate_byte_lane_hburst_seq_busy_park_pipeline_cli`,
`source_kind: ial2_profile_alias`, and generated module
`ahb_lite_subordinate_byte_lane_hburst_seq_busy_park`. It preserves the generated
`.isf`/`.fsm` review artifacts, `bindings.bus.burst`, and the distinctive
BUSY-park `transfer.seq_policy` shape (`mode: hburst_in_word_progressive`,
`parks_on: [busy]`, `clears_on: [reset, idle, error, new_nonseq, final_beat]`,
supported `WRAP4`/`INCR4`).

The alias report removes `ahb_subordinate_profile_alias_deferred` and the `.ahb
alias exposure` residue wording through the existing suffix-keyed profile-alias
suppression (`PPIF.pm` `_is_ahb_profile_alias_source` / the subordinate
`.ahb`-suffix branch), with no adapter change; the generic `.ppif` report keeps
that source-surface residue. Focused coverage is
`t/1495-ial2-ahb-subordinate-byte-lane-hburst-seq-busy-park-profile-alias.t`;
`t/248` moves to 293 protocol / 334 total supported-smoke entries and `t/297`
carries the manifest surface. Aggregate BUSY-parking, requester-side BUSY
insertion, halfword/word burst `SEQ`, wider or indefinite bursts, broader AHB,
AXI/APB, and VHDL remain deferred.
