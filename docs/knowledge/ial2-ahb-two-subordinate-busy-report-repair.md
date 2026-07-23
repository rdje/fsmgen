---
id: ial2-ahb-two-subordinate-busy-report-repair
title: Two-subordinate AHB BUSY-park broader residue now agrees with shipped parking
answers:
  - "was the contradictory two-subordinate AHB BUSY report repaired?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.799 change?"
  - "do non-parking two-subordinate AHB reports still defer BUSY continuation?"
  - "did the AHB BUSY report repair change HDL or runtime behavior?"
date: 2026-07-23
status: current
tags: [ial2, ahb, interconnect, busy, report, residue, preservation]
evidence: docs/IAL2_AHB_TWO_SUBORDINATE_BUSY_REPORT_REPAIR.md; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; t/1492-ial2-ahb-interconnect-byte-lane-hburst-seq.t; t/1493-ial2-ahb-interconnect-byte-lane-hburst-seq-profile-alias.t; t/1496-ial2-ahb-interconnect-byte-lane-hburst-seq-busy-park.t; t/1497-ial2-ahb-interconnect-byte-lane-hburst-seq-busy-park-profile-alias.t; docs/IAL2_AHB_AGGREGATE_BUSY_PARK_PROPAGATION_BEHAVIOR.md; docs/IAL2_AHB_AGGREGATE_BUSY_PARK_PROPAGATION_PROFILE_ALIAS_BEHAVIOR.md; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; MEMORY.md
reverify: rg -n 'hburst_busy_park_selected|ahb_broader_interconnect_decode_deferred|BUSY-in-burst continuation|with BUSY-in-burst parking|IAL2-FEATURE-COMPLETENESS-FRONTIER\.799|IAL2-FEATURE-COMPLETENESS-FRONTIER\.800' perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm t/1492-ial2-ahb-interconnect-byte-lane-hburst-seq.t t/1493-ial2-ahb-interconnect-byte-lane-hburst-seq-profile-alias.t t/1496-ial2-ahb-interconnect-byte-lane-hburst-seq-busy-park.t t/1497-ial2-ahb-interconnect-byte-lane-hburst-seq-busy-park-profile-alias.t docs/IAL2_AHB_TWO_SUBORDINATE_BUSY_REPORT_REPAIR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/book/src/16c-ial2-ahb.md MEMORY.md
---

`.799` repaired report-only drift. For two-subordinate HBURST sources whose
children all park BUSY, the broader interconnect residue now records shipped
byte-only WRAP4/INCR4 in-word SEQ propagation with BUSY-in-burst parking and no
longer defers BUSY continuation. The dedicated burst residue already made that
claim.

Non-parking two-subordinate generic and alias reports retain BUSY-continuation
deferral. One-subordinate reports, residue ids/shape, public sources, generated
artifacts, support counts, and HDL/runtime behavior are unchanged. `.800` owns
the paired public contract selection.
