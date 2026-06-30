---
id: ial2-ahb-aggregate-byte-lane-profile-alias-behavior
title: AHB aggregate byte-lane profile aliases shipped
answers:
  - "are matching AHB aggregate byte-lane .ahb aliases shipped?"
  - "does FSMGen ship ppif/ahb_interconnect_byte_lane.ahb?"
  - "does FSMGen ship ppif/ahb_interconnect_two_subordinate_byte_lane.ahb?"
  - "what support accounting identifies AHB aggregate byte-lane .ahb aliases?"
  - "do AHB aggregate byte-lane aliases preserve byte-lane propagation?"
date: 2026-06-30
status: current
tags: [ial2, ahb, interconnect, aggregate, byte-lane, profile-alias, behavior]
evidence: docs/IAL2_AHB_AGGREGATE_BYTE_LANE_PROFILE_ALIAS_BEHAVIOR.md; ppif/ahb_interconnect_byte_lane.ahb; ppif/ahb_interconnect_two_subordinate_byte_lane.ahb; ppif/ahb_interconnect_byte_lane.ppif; ppif/ahb_interconnect_two_subordinate_byte_lane.ppif; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1485-ial2-ahb-interconnect-byte-lane-profile-alias.t; t/297-capability-manifest.t; docs/book/src/16c-ial2-ahb.md; docs/book/src/16-ial2-protocol-platform-intent.md; docs/book/src/14-feature-backlog.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: prove -Iperl t/1485-ial2-ahb-interconnect-byte-lane-profile-alias.t && ./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_byte_lane.ahb && ./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_two_subordinate_byte_lane.ahb && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.745|ppif/ahb_interconnect_byte_lane\.ahb|ppif/ahb_interconnect_two_subordinate_byte_lane\.ahb|intent\.ahb_profile_alias_interconnect_byte_lane|intent\.ahb_profile_alias_interconnect_two_subordinate_byte_lane|composition\.byte_lane_propagation|ahb_aggregate_profile_alias_deferred' docs/IAL2_AHB_AGGREGATE_BYTE_LANE_PROFILE_ALIAS_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md MEMORY.md docs/book/src/16c-ial2-ahb.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.745` ships
`ppif/ahb_interconnect_byte_lane.ahb` and
`ppif/ahb_interconnect_two_subordinate_byte_lane.ahb` as bounded public AHB
aggregate byte-lane profile aliases over the generic aggregate byte-lane
`.ppif` sources.

The aliases support-account as
`intent.ahb_profile_alias_interconnect_byte_lane` and
`intent.ahb_profile_alias_interconnect_two_subordinate_byte_lane`, both with
source kind `ial2_profile_alias`, HDL module `ahb_tb`, and composition child
counts 3 and 4.

Both aliases preserve generated `.isf` before generated `.fsm` review
artifacts, `composition.byte_lane_propagation`, child
`narrow_transfer_policy`, subtract-window-base local-address policy before
byte-lane selection, subordinate-owned mapped-hit byte/halfword/word behavior,
and interconnect-owned unmapped ERROR behavior. Alias reports remove
`ahb_aggregate_profile_alias_deferred`; generic aggregate byte-lane `.ppif`
reports keep that residue as a source-surface distinction.
