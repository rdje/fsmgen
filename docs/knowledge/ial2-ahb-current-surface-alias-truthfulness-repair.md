---
id: ial2-ahb-current-surface-alias-truthfulness-repair
title: Current AHB book and behavior facts acknowledge all shipped aggregate and paired aliases
answers:
  - "do all selected aggregate AHB profile aliases ship?"
  - "are aggregate HBURST and BUSY-park aliases current in the mdBook?"
  - "what does t 1518 protect?"
  - "how was stale AHB alias deferral documentation repaired?"
  - "did the AHB alias truthfulness repair change runtime behavior?"
date: 2026-07-23
status: current
tags: [ial2, ahb, mdbook, documentation, alias, truthfulness, repair]
evidence: >-
  docs/IAL2_AHB_CURRENT_SURFACE_ALIAS_TRUTHFULNESS_REPAIR.md; docs/IAL2_POST_REQUESTER_WRAP_REPAIR_NEXT_OWNER_SELECTION.md; docs/book/src/16-ial2-protocol-platform-intent.md; docs/book/src/16c-ial2-ahb.md; docs/IAL2_AHB_AGGREGATE_HBURST_SEQ_BEHAVIOR.md; docs/IAL2_AHB_AGGREGATE_BUSY_PARK_PROPAGATION_BEHAVIOR.md; docs/IAL2_AHB_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md; docs/knowledge/ial2-ahb-aggregate-hburst-seq-behavior.md; docs/knowledge/ial2-ahb-aggregate-busy-park-propagation-behavior.md; docs/knowledge/ial2-ahb-paired-busy-composition-behavior.md; ppif/ahb_interconnect_byte_lane_hburst_seq.ahb; ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ahb; ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ahb; ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ahb;
  ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ahb; ppif/ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park.ahb; t/1518-ial2-ahb-mdbook-current-surface-truthfulness.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md
reverify: prove -Iperl t/1518-ial2-ahb-mdbook-current-surface-truthfulness.t
---

`.806` aligns the mdBook's current AHB navigation/mode guidance and three
canonical behavior/fact pairs with six checked-in aggregate/paired `.ahb`
aliases. It preserves historical time-local statements and changes no
code/source/support/report/artifact/HDL/runtime contract.

t/1518 requires the six alias paths, positive current-book/current-behavior
claims, and absence of the exact stale current deferrals. Existing t1493,
t1497, t1514, and t1516 remain the alias parity owners; t1492, t1496, t1513,
and t1515 remain the corresponding runtime owners. Boundary-free active-
transfer pipelining and decision 0020 stay proposed/inactive.
