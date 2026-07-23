---
id: ial2-ahb-paired-busy-composition-readiness-audit
title: One paired AHB requester-BUSY/subordinate-park aggregate is implementation-ready after contract selection
answers:
  - "is paired AHB requester BUSY insertion and subordinate BUSY parking ready?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.792 conclude?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.793?"
  - "why does an aggregate AHB requester child lose busy_insertion metadata?"
  - "how can generated HDL prove AHB BUSY insertion and parking end to end?"
  - "what artifacts does a paired AHB BUSY composition generate?"
date: 2026-07-23
status: current
tags: [ial2, ahb, requester, subordinate, busy, composition, report, runtime, readiness]
evidence: docs/IAL2_AHB_PAIRED_BUSY_COMPOSITION_READINESS_AUDIT.md; docs/IAL2_POST_AHB_REQUESTER_BUSY_INSERTION_ALIAS_NEXT_SLICE_SELECTION.md; ppif/ahb_requester_busy_insert.ppif; ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ppif; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; t/1494-ial2-ahb-subordinate-byte-lane-hburst-seq-busy-park.t; t/1496-ial2-ahb-interconnect-byte-lane-hburst-seq-busy-park.t; t/1498-ial2-ahb-requester-busy-insert.t; t/1512-ial2-ahb-requester-busy-insert-profile-alias.t; docs/book/src/16c-ial2-ahb.md; docs/book/src/14-feature-backlog.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: rg -n 'sub _child_report|busy_insertion|sub _top_port_specs|comp_link_requester_HTRANS' perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm docs/IAL2_AHB_PAIRED_BUSY_COMPOSITION_READINESS_AUDIT.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.792` confirms the existing aggregate path
can compose the shipped BUSY-inserting requester and HBURST-aware BUSY-parking
subordinate without parser, endpoint-generator, wiring, top, or HDL substrate
repair. The in-memory candidate emits `amba_requester_busy_insert`,
`ahb_lite_subordinate_byte_lane_hburst_seq`, `ahb_interconnect`, and `ahb_tb`
IAL1/IAL0 artifacts; requester transfer/residue retains BUSY insertion, while
the subordinate and aggregate propagation retain `parks_on = [busy]`.

The only required code delta identified by the audit is narrow report
propagation: `AhbInterconnect::_child_report` omits the optional standalone
requester `busy_insertion` block. An additive conditional clone affects only
aggregates containing that requester and preserves base aggregates.

Generated `ahb_tb` already exposes command/status ports and deterministic
internal requester bus nets plus subordinate state/storage for a focused
Verilator proof. `.792` therefore selects `.793`, a no-behavior public contract
selection for one generic `.ppif` one-subordinate composition, report shape,
support identity, and exact runtime test. The alias, two-subordinate sibling,
broader BUSY policies/status, larger bursts, optional signals, backends,
AXI/APB, and VHDL remain deferred. Decision `0020` remains proposed/inactive.

`.793` subsequently selected
`ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ppif`
for `.794` implementation. Fact
`ial2-ahb-paired-busy-composition-contract-selection` owns the exact source,
support, report, t/1513/runtime, accounting, and preservation contract.
