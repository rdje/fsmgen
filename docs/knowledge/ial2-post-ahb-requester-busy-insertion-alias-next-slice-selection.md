---
id: ial2-post-ahb-requester-busy-insertion-alias-next-slice-selection
title: The completed AHB requester BUSY .ppif/.ahb pair selects a paired composition readiness audit
answers:
  - "what follows the AHB requester BUSY-insertion .ppif and .ahb sources?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.791 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.792?"
  - "is an end-to-end requester BUSY and subordinate BUSY-park composition ready?"
  - "does an AHB aggregate child report propagate requester busy_insertion?"
  - "why is paired AHB BUSY composition audited before implementation?"
date: 2026-07-23
status: current
tags: [ial2, ahb, requester, subordinate, busy, composition, report, readiness, selector]
evidence: docs/IAL2_POST_AHB_REQUESTER_BUSY_INSERTION_ALIAS_NEXT_SLICE_SELECTION.md; docs/IAL2_AHB_REQUESTER_BUSY_INSERTION_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_AHB_REQUESTER_BUSY_INSERTION_BEHAVIOR.md; docs/IAL2_AHB_AGGREGATE_BUSY_PARK_PROPAGATION_BEHAVIOR.md; ppif/ahb_requester_busy_insert.ppif; ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ppif; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; t/1496-ial2-ahb-interconnect-byte-lane-hburst-seq-busy-park.t; t/1498-ial2-ahb-requester-busy-insert.t; t/1512-ial2-ahb-requester-busy-insert-profile-alias.t; docs/book/src/16c-ial2-ahb.md; docs/book/src/14-feature-backlog.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: rg -n 'sub _child_report|busy_insertion|parks_on' perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm docs/IAL2_POST_AHB_REQUESTER_BUSY_INSERTION_ALIAS_NEXT_SLICE_SELECTION.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.791` selects `.792`, a no-behavior
readiness audit for one bounded requester/subordinate BUSY composition after the
requester BUSY-insertion `.ppif`/`.ahb` pair shipped.

A current-state source-shape probe shows the existing aggregate generator can
compose `amba_requester_busy_insert` with the HBURST-aware byte-lane subordinate
that parks BUSY. It emits the requester, subordinate, interconnect, and top
`.isf`/`.fsm` artifacts; the requester child retains
`ahb_requester_busy_insert_support`; and the subordinate child plus aggregate
propagation report `parks_on = [busy]`.

Direct implementation is not yet selected because the probe found a reporting
gap: standalone requester JSON exposes `busy_insertion`, but
`AhbInterconnect::_child_report` does not copy that optional block into the
aggregate requester-child view. `.792` must settle report propagation, the
one-subordinate source/identity boundary, and exact generated-HDL end-to-end
proof before implementation. Larger BUSY policies, local bus-BUSY status,
multi-word/larger bursts, optional signals, backends, AXI/APB, and VHDL remain
deferred. Decision `0020` remains proposed/inactive.
