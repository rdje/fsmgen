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
date: 2026-07-23
status: current
tags: [ial2, ahb, requester, subordinate, interconnect, busy, composition, runtime, behavior]
evidence: ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ppif; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; perl/FSM/Support/RegressionCorpus.pm; t/1513-ial2-ahb-paired-busy-composition.t; t/data/ahb_paired_busy_composition_tb.svt; docs/IAL2_AHB_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
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
`NONSEQ(0) -> SEQ(1) -> BUSY(2 held) -> SEQ(2 resumed) -> SEQ(3)`, one BUSY
presentation, four completed byte beats, held requester/subordinate state and
storage on BUSY, OKAY completion with zero remaining, and final storage
`32'h44332211`.

The proof also corrected the reused AHB endpoint phase path: the requester
holds a presented transfer until data-phase `HREADY`; the subordinate claims
one active transfer through `ahb_access_active_q`; continuation clearing is a
concurrent rule rather than a competing transaction; runtime wait cycles use
width-safe counted repeats; the interconnect child instance is `fabric`; and a
zero-base decode omits `HADDR >= 0`. The paired source passes public
`--verify-hdl`. The paired `.ahb` alias and generic two-subordinate paired
sibling now ship through later task-tree slices. True pipelined active
transfers without an IDLE/BUSY/unselected boundary and the matching
two-subordinate `.ahb` alias remain deferred.
