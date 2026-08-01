---
id: ial2-ahb-two-subordinate-paired-busy-readiness-audit
title: Two-subordinate paired AHB BUSY generation is ready after a report-only prerequisite
answers:
  - "is the two-subordinate paired AHB BUSY composition implementation-ready?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.798 find?"
  - "why must AHB BUSY residue be repaired before the two-subordinate paired source?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.799 own?"
  - "how can the future two-subordinate paired AHB BUSY runtime proof cover both windows?"
date: 2026-07-23
status: current
tags: [ial2, ahb, requester, subordinate, interconnect, busy, readiness, residue]
evidence: >-
  docs/IAL2_AHB_TWO_SUBORDINATE_PAIRED_BUSY_READINESS_AUDIT.md; docs/IAL2_POST_AHB_PAIRED_BUSY_FAMILY_NEXT_SLICE_SELECTION.md; ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ppif; ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ahb; ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ppif; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; t/1492-ial2-ahb-interconnect-byte-lane-hburst-seq.t; t/1493-ial2-ahb-interconnect-byte-lane-hburst-seq-profile-alias.t; t/1496-ial2-ahb-interconnect-byte-lane-hburst-seq-busy-park.t; t/1497-ial2-ahb-interconnect-byte-lane-hburst-seq-busy-park-profile-alias.t; t/1513-ial2-ahb-paired-busy-composition.t; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md;
  MEMORY.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.798|IAL2-FEATURE-COMPLETENESS-FRONTIER\.799|IAL2-FEATURE-COMPLETENESS-FRONTIER\.800|hburst_busy_park_selected|BUSY-in-burst continuation|21,656|HADDR_CONTROL' docs/IAL2_AHB_TWO_SUBORDINATE_PAIRED_BUSY_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/book/src/16c-ial2-ahb.md perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm
---

`.798` proved a temporary two-subordinate paired candidate across check,
schedule, semantic, review-artifact, SystemVerilog, and Yosys surfaces. The
candidate reports four children, requester `busy_insertion`, both child and
propagated `parks_on=[busy]`, exact status/control windows, module `ahb_tb`, and
the expected four IAL1/five IAL0 artifacts. No parser, generator, wiring, phase,
decode, mux, top, or HDL substrate prerequisite was found.

Before public contract selection, `.799` repairs shipped report drift:
two-subordinate parked reports currently say BUSY continuation is deferred in
`ahb_broader_interconnect_decode_deferred` while their dedicated burst residue
says BUSY parking ships. The broader branch ignores the already-computed
`hburst_busy_park_selected` predicate. `.799` must fix only that wording,
preserve BUSY deferral for non-parking sources, and leave behavior/counts intact.

`.800` then owns the paired public contract. Its runtime proof can run separate
status-base-0 and control-base-4 byte `INCR4` commands, check the same held BUSY
sequence for each selected child, prove the other child is unaffected, verify
control local-address subtraction, and distinguish the two storage results.
Decision `0020` and proposed audits remain inactive.
