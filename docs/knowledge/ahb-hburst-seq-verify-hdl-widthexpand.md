---
id: ahb-hburst-seq-verify-hdl-widthexpand
title: AHB HBURST SEQ wait warning fixed; current source-intent gate fails
answers:
  - "does the AHB HBURST SEQ subordinate pass --verify-hdl?"
  - "how was the AHB dynamic wait WIDTHEXPAND warning resolved?"
  - "what happened to the Verilator WIDTHEXPAND warnings on ahb_lite_subordinate_byte_lane_hburst_seq?"
  - "is --verify-hdl a clean gate for the AHB HBURST SEQ family now?"
date: 2026-11-01
status: current
tags: [ial2, ahb, hburst, seq, verify-hdl, verilator, widthexpand, finding]
evidence: ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif; ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm
reverify: ./bin/fsmgen --quiet --strict --verify-hdl ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif; ./bin/fsmgen --quiet --strict --verify-hdl ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif; ./bin/fsmgen --quiet --strict --verify-hdl ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ppif
---

`.794` fixed the two base/BUSY-park WIDTHEXPAND warnings (four-bit dynamic-wait
counter versus `1'b1`), not a BUSY-park regression. Its first paired
requester/subordinate BUSY composition uses AHB sampled `wait_cycles` as counted
one-cycle repeats: sampled counter width, zero comparison/bypass, nonzero delay.
Generic ISF dynamic waits/APB generation were unchanged. That epoch qualified
`--verify-hdl` for HBURST `SEQ`, BUSY-park and paired BUSY compositions.

2026-11-01 full10: supported HBURST/SEQ subordinate/interconnect check, semantic
and HDL paths refuse completed source intent at
`SourceLiteralWidthSupport::capture_generation_fence` line712. T1490-T1492 fail;
T1493 is partial. Cause unknown, owned by `PUBLICATION-REGRESSION-REPAIRS.23`,
separate from the old warning. Support remains; a clean gate needs causal repair/requalification. Evidence:
`docs/audits/push-readiness-20261025/full10-intake-20261101.json.gz`.
