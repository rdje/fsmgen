---
id: ial2-ahb-two-subordinate-paired-busy-composition-behavior
title: The two-subordinate AHB aggregate pairs requester BUSY insertion with both parked windows
answers:
  - "does FSMGen ship a two-subordinate paired AHB BUSY composition?"
  - "what does the two-subordinate paired AHB BUSY source do?"
  - "what shipped in IAL2-FEATURE-COMPLETENESS-FRONTIER.801?"
  - "what does t 1515 prove?"
  - "does the paired AHB BUSY runtime cover both status and control windows?"
  - "is the two-subordinate paired AHB BUSY source a new generator?"
date: 2026-07-23
status: current
tags: [ial2, ahb, requester, subordinate, interconnect, busy, composition, runtime, behavior]
evidence: ppif/ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park.ppif; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1515-ial2-ahb-two-subordinate-paired-busy-composition.t; t/data/ahb_two_subordinate_paired_busy_composition_tb.svt; docs/IAL2_AHB_TWO_SUBORDINATE_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
reverify: prove -Iperl t/1492-ial2-ahb-interconnect-byte-lane-hburst-seq.t t/1493-ial2-ahb-interconnect-byte-lane-hburst-seq-profile-alias.t t/1496-ial2-ahb-interconnect-byte-lane-hburst-seq-busy-park.t t/1497-ial2-ahb-interconnect-byte-lane-hburst-seq-busy-park-profile-alias.t t/1513-ial2-ahb-paired-busy-composition.t t/1514-ial2-ahb-paired-busy-composition-profile-alias.t t/1515-ial2-ahb-two-subordinate-paired-busy-composition.t && ./bin/fsmgen --quiet --strict --verify-hdl ppif/ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park.ppif
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.801` ships
`ppif/ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park.ppif`.
The one-requester/two-subordinate aggregate pairs one intended requester BUSY
episode before beat two with BUSY parking in both the status and control
HBURST-aware byte-lane subordinates. It reuses the existing IAL2-to-IAL1-to-
IAL0-to-HDL generator pipeline; the additive public source is not a separate
generator.

Schedule/report JSON exposes requester-child `busy_insertion`, both child and
propagated `parks_on: [busy]` policies, exact status `[0,4)` and control
`[4,8)` windows, four IAL1/five IAL0 artifacts, and no duplicate `busy_flow`.
Support accounting is 313 protocol fixtures and 354 supported-smoke/strict
entries.

Generated-HDL t/1515 runs status-base-0 and control-base-4 byte `INCR4`
commands. Each proves
`NONSEQ(0) -> SEQ(1) -> BUSY(2 held) -> SEQ(2 resumed) -> SEQ(3)`, one BUSY
transition episode, four completed data beats, selected-child parking, unselected-child
non-interference, correct control local-address subtraction, OKAY/zero
completion, and final status/control storage `32'h44332211`/`32'h88776655`.
It does not count every ready-qualified BUSY edge; fact
`ial2-ahb-requester-multi-busy-insertion-readiness-audit` records the embedded
requester's current ten-edge versus `beats=single` contradiction.
The matching `.ahb` alias now ships through `.803`; broader BUSY/status/burst
behavior remains deferred.
