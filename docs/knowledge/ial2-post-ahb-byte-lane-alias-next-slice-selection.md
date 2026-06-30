---
id: ial2-post-ahb-byte-lane-alias-next-slice-selection
title: Post AHB byte-lane alias selector chooses aggregate byte-lane readiness audit
answers:
  - "what follows AHB byte-lane .ahb alias behavior?"
  - "which task owns AHB aggregate byte-lane propagation readiness?"
  - "why audit aggregate byte-lane propagation after .739?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.740 select?"
  - "is aggregate/interconnect byte-lane propagation next after the byte-lane alias?"
date: 2026-06-30
status: current
tags: [ial2, ahb, interconnect, aggregate, byte-lane, narrow-transfer, task-tree]
evidence: docs/IAL2_POST_AHB_BYTE_LANE_ALIAS_NEXT_SLICE_SELECTION.md; docs/IAL2_AHB_BYTE_LANE_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_AHB_BYTE_LANE_NARROW_TRANSFER_BEHAVIOR.md; docs/IAL2_AHB_INTERCONNECT_DECODE_BEHAVIOR.md; docs/IAL2_AHB_TWO_SUBORDINATE_BEHAVIOR.md; ppif/ahb_lite_subordinate_byte_lane.ppif; ppif/ahb_lite_subordinate_byte_lane.ahb; ppif/ahb_interconnect.ppif; ppif/ahb_interconnect_two_subordinate.ppif; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; perl/FSM/Adapter/IAL2/PPIF.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/book/src/16c-ial2-ahb.md
reverify: ./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_lite_subordinate_byte_lane.ahb && ./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect.ahb && ./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_two_subordinate.ahb && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.740|IAL2-FEATURE-COMPLETENESS-FRONTIER\.741|aggregate/interconnect byte-lane|ahb_lite_subordinate_byte_lane|byte lanes are deferred' docs/IAL2_POST_AHB_BYTE_LANE_ALIAS_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md MEMORY.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.740` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.741`, a no-behavior readiness audit for
AHB aggregate/interconnect byte-lane and narrow-transfer propagation.

The endpoint byte-lane subordinate now ships as both
`ppif/ahb_lite_subordinate_byte_lane.ppif` and
`ppif/ahb_lite_subordinate_byte_lane.ahb`. Current aggregate sources still use
word-only subordinate objects and still keep byte lanes in aggregate residue.

In-memory current-code probes showed that one-subordinate and two-subordinate
aggregate candidates can parse with byte-lane subordinate policies and emit
byte-lane subordinate review artifacts, but their reports still describe byte
lanes as deferred. `.741` therefore audits the source shape, report/residue
movement, support identities, validation plan, and `.ahb` alias sequencing
before any public aggregate byte-lane source is added.
