---
id: ial2-post-ahb-paired-busy-family-next-slice-selection
title: Post paired AHB BUSY family selection chooses two-subordinate pairing readiness
answers:
  - "what follows the paired AHB BUSY .ppif and .ahb family?"
  - "which task owns two-subordinate paired AHB BUSY readiness?"
  - "why is two-subordinate paired BUSY composition next?"
  - "can the current generator compose a BUSY requester with two BUSY-parking subordinates?"
  - "which two-subordinate AHB BUSY residue wording is contradictory?"
date: 2026-07-23
status: current
tags: [ial2, ahb, requester, subordinate, interconnect, busy, composition, selection]
evidence: docs/IAL2_POST_AHB_PAIRED_BUSY_FAMILY_NEXT_SLICE_SELECTION.md; docs/IAL2_AHB_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_AHB_AGGREGATE_BUSY_PARK_PROPAGATION_BEHAVIOR.md; ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ppif; ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ppif; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; t/1496-ial2-ahb-interconnect-byte-lane-hburst-seq-busy-park.t; t/1513-ial2-ahb-paired-busy-composition.t; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.797|IAL2-FEATURE-COMPLETENESS-FRONTIER\.798|two-subordinate paired|BUSY-in-burst continuation|hburst_busy_park_selected' docs/IAL2_POST_AHB_PAIRED_BUSY_FAMILY_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/book/src/16c-ial2-ahb.md perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm
---

After the one-subordinate paired BUSY `.ppif`/`.ahb` family completed, `.797`
selected `.798`, a no-behavior readiness audit for the two-subordinate paired
composition. An in-memory candidate already generates one BUSY requester, two
BUSY-parking HBURST byte-lane subordinates, the interconnect, and `ahb_tb`; it
reports four children, requester `busy_insertion`, and `parks_on=[busy]` for both
subordinates and both propagated policies.

Readiness rather than direct implementation is selected because the topology
needs an exact two-window runtime proof and because the shipped report has a
contradiction. `ahb_broader_interconnect_decode_deferred` still says
BUSY-in-burst continuation is future work, while
`ahb_burst_seq_support_deferred` correctly says BUSY parking ships. The cause is
that the broader two-subordinate residue branches only on HBURST policy, not the
already-computed BUSY-park predicate. `.798` owns selecting the report-only
repair and preserving the non-parking negative case before public implementation.

Broader BUSY policy/status, larger or multi-word bursts, optional signals,
proposed audits, decision `0020`, backends, AXI/APB, and VHDL remain inactive or
deferred.
