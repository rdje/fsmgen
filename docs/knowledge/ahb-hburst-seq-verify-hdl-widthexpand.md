---
id: ahb-hburst-seq-verify-hdl-widthexpand
title: AHB HBURST SEQ subordinate wait counters are clean under --verify-hdl
answers:
  - "does the AHB HBURST SEQ subordinate pass --verify-hdl?"
  - "how was the AHB dynamic wait WIDTHEXPAND warning resolved?"
  - "what happened to the Verilator WIDTHEXPAND warnings on ahb_lite_subordinate_byte_lane_hburst_seq?"
  - "is --verify-hdl a clean gate for the AHB HBURST SEQ family now?"
date: 2026-07-23
status: current
tags: [ial2, ahb, hburst, seq, verify-hdl, verilator, widthexpand, finding]
evidence: ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif; ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm
reverify: ./bin/fsmgen --quiet --strict --verify-hdl ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif; ./bin/fsmgen --quiet --strict --verify-hdl ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif; ./bin/fsmgen --quiet --strict --verify-hdl ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ppif
---

Before `IAL2-FEATURE-COMPLETENESS-FRONTIER.794`, the byte-lane HBURST `SEQ`
family emitted two Verilator `WIDTHEXPAND` warnings on comparisons such as a
four-bit dynamic-wait counter against `1'b1`. The base and BUSY-park sources
had the identical warning, proving it was family-wide rather than a BUSY-park
regression.

`.794` resolved the AHB-local warning while proving the first paired
requester/subordinate BUSY composition. Generated AHB subordinates now express
sampled `wait_cycles` as a counted repetition of one-cycle waits. Existing
repeat lowering keeps the runtime counter at the sampled width and terminates
against zero, avoiding the one-bit literal comparison. Zero counts bypass the
body and nonzero counts preserve the sampled delay.

`--verify-hdl` is now a clean public gate for the AHB HBURST `SEQ`, BUSY-park,
and paired BUSY-composition sources. Generic ISF dynamic-wait lowering and APB
wait generation were not changed by `.794`.
