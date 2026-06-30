---
id: ial2-ahb-byte-lane-profile-alias-behavior
title: AHB byte-lane subordinate .ahb profile alias shipped
answers:
  - "does the AHB byte-lane subordinate have an .ahb alias?"
  - "what is ppif/ahb_lite_subordinate_byte_lane.ahb?"
  - "how is the AHB byte-lane .ahb alias support-accounted?"
  - "does byte-lane subordinate .ahb preserve narrow_transfer_policy?"
  - "does byte-lane subordinate .ahb remove ahb_subordinate_profile_alias_deferred?"
date: 2026-06-30
status: current
tags: [ial2, ahb, byte-lane, narrow-transfer, profile-alias, behavior]
evidence: docs/IAL2_AHB_BYTE_LANE_PROFILE_ALIAS_BEHAVIOR.md; ppif/ahb_lite_subordinate_byte_lane.ahb; ppif/ahb_lite_subordinate_byte_lane.ppif; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1483-ial2-ahb-subordinate-byte-lane-profile-alias.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/book/src/16c-ial2-ahb.md; docs/book/src/16-ial2-protocol-platform-intent.md; docs/book/src/14-feature-backlog.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: prove -v t/1483-ial2-ahb-subordinate-byte-lane-profile-alias.t && ./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate_byte_lane.ahb && ./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_lite_subordinate_byte_lane.ahb
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.739` ships
`ppif/ahb_lite_subordinate_byte_lane.ahb` as the bounded public AHB
byte-lane/narrow-transfer subordinate `.ahb` profile alias.

The alias mirrors `ppif/ahb_lite_subordinate_byte_lane.ppif`, keeps explicit
`(profile ahb)`, lowers through generated
`ahb_lite_subordinate_byte_lane.isf` before generated
`ahb_lite_subordinate_byte_lane.fsm`, and emits HDL module
`ahb_lite_subordinate_byte_lane`.

The support-accounting identity is
`intent.ahb_profile_alias_subordinate_byte_lane`, source kind
`ial2_profile_alias`, and coverage
`ial2_ahb_profile_alias_subordinate_byte_lane_pipeline_cli`.

The `.ahb` schedule/report JSON preserves `narrow_transfer_policy` and removes
`ahb_subordinate_profile_alias_deferred` from the alias report. The generic
byte-lane `.ppif` report keeps that alias-deferred residue.
