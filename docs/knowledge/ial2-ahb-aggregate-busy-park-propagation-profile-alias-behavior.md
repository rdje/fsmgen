---
id: ial2-ahb-aggregate-busy-park-propagation-profile-alias-behavior
title: AHB aggregate BUSY-park .ahb profile aliases shipped
answers:
  - "does FSMGen ship aggregate AHB BUSY-park .ahb profile aliases?"
  - "what does ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ahb generate?"
  - "how are the aggregate BUSY-park .ahb aliases support-accounted?"
date: 2026-07-12
status: current
tags: [ial2, ahb, busy-park, aggregate, profile-alias, behavior]
evidence: docs/IAL2_AHB_AGGREGATE_BUSY_PARK_PROPAGATION_PROFILE_ALIAS_BEHAVIOR.md; ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ahb; ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ahb; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1497-ial2-ahb-interconnect-byte-lane-hburst-seq-busy-park-profile-alias.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: prove -Iperl t/1497-ial2-ahb-interconnect-byte-lane-hburst-seq-busy-park-profile-alias.t && ./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ahb
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.784` ships the matching aggregate AHB
BUSY-park HBURST-aware byte-lane `SEQ` `.ahb` profile aliases
`ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ahb` (child count 3) and
`ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ahb`
(child count 4), byte-identical mirrors of the `.782` shipped generic BUSY-park
`.ppif` sources.

They support-account as
`intent.ahb_profile_alias_interconnect_byte_lane_hburst_seq_busy_park` and
`intent.ahb_profile_alias_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park`,
source kind `ial2_profile_alias`, HDL module `ahb_tb`. The aliases produce
identical generated review artifacts, HDL, and
`composition.seq_policy_propagation` reports (each child `parks_on = [busy]` /
BUSY-free `clears_on`) as the generic sources, differing only in that the alias
reports drop `ahb_aggregate_profile_alias_deferred`,
`ahb_subordinate_profile_alias_deferred`, and the `.ahb alias exposure` residue
wording through the existing suffix-keyed suppression (no adapter change).

Focused coverage `t/1497`; `t/248` moved to 297 protocol / 338 total.
Requester-side BUSY insertion, halfword/word burst `SEQ`, wider/indefinite
bursts, multi-word/register-bank progression, optional AHB signals, broader AHB,
backend variants, AXI/APB, and VHDL remain deferred.
