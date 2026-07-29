---
id: ial2-ahb-paired-busy-composition-behavior
title: The paired AHB aggregate composes one requester BUSY insertion with subordinate BUSY parking
answers:
  - "does FSMGen compose requester AHB BUSY insertion with subordinate BUSY parking?"
  - "what does the paired AHB BUSY composition source do?"
  - "what shipped in IAL2-FEATURE-COMPLETENESS-FRONTIER.794?"
  - "what does t 1513 prove?"
  - "how does generated AHB phase ownership avoid duplicate transfer admission?"
  - "is the paired AHB BUSY source clean under verify hdl?"
date: 2026-07-24
status: current
tags: [ial2, ahb, requester, subordinate, interconnect, busy, composition, runtime, behavior]
evidence: ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ppif; ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ahb; ppif/ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park.ppif; ppif/ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park.ahb; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; perl/FSM/Support/RegressionCorpus.pm; t/1513-ial2-ahb-paired-busy-composition.t; t/1514-ial2-ahb-paired-busy-composition-profile-alias.t; t/1515-ial2-ahb-two-subordinate-paired-busy-composition.t; t/1516-ial2-ahb-two-subordinate-paired-busy-composition-profile-alias.t; t/data/ahb_paired_busy_composition_tb.svt; docs/IAL2_AHB_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md; docs/IAL2_AHB_TWO_SUBORDINATE_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_BEHAVIOR.md; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
reverify: prove -Iperl t/1473-ial2-ahb-requester.t t/1475-ial2-ahb-subordinate.t t/1478-ial2-ahb-interconnect.t t/1494-ial2-ahb-subordinate-byte-lane-hburst-seq-busy-park.t t/1496-ial2-ahb-interconnect-byte-lane-hburst-seq-busy-park.t t/1498-ial2-ahb-requester-busy-insert.t t/1513-ial2-ahb-paired-busy-composition.t && ./bin/fsmgen --quiet --strict --verify-hdl ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ppif
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.794` ships
`ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ppif`.
The one-requester/one-subordinate aggregate pairs `(busy-before-beat 2)` with
the HBURST-aware byte-lane subordinate's `(parked-transfer busy)` policy. Its
requester child exposes `busy_insertion`, its subordinate child and aggregate
SEQ-policy propagation expose `parks_on: [busy]`, and no duplicate top
`busy_flow` summary is added.

Generated-HDL t/1513 proves
`NONSEQ(0) -> SEQ(1) -> BUSY(2 held) -> SEQ(2 resumed) -> SEQ(3)`, exactly one
ready-and-grant-qualified BUSY event, four completed byte beats, held
requester/subordinate state and storage on BUSY, OKAY completion with zero
remaining, and final storage `32'h44332211`. t/1514 independently runs the
same exact-event harness against alias-generated HDL.

Current generated phase behavior separates requester address/data ownership,
retires accepted `HTRANS` to IDLE, captures HRESP/HRDATA on data completion,
banks one accepted subordinate address/control phase through
`ahb_phase_pending_q`, and retains one one-hot interconnect data-phase owner.
Continuation clearing remains a concurrent rule; runtime waits remain
width-safe counted repeats; the interconnect child instance is `fabric`; and a
zero-base decode omits `HADDR >= 0`. The paired source passes public
`--verify-hdl`. The paired `.ahb` alias and generic two-subordinate paired
sibling now ship through later task-tree slices. The matching two-subordinate
alias also ships; current behavior is documented in
`IAL2_AHB_TWO_SUBORDINATE_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_BEHAVIOR`.
t/1519 separately proves boundary-free active-phase retention. The later
interconnect and generated-subordinate arbitration repairs let paired tests
run with all selector assertions enabled while retaining the same qualified
BUSY counts.
General/deeper queues, multiple outstanding transfers, and broader
manager/fabric behavior remain deferred.
