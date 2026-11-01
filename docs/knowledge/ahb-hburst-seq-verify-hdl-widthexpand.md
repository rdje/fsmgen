---
id: ahb-hburst-seq-verify-hdl-widthexpand
title: AHB HBURST SEQ source gate repaired; full qualification pending
answers:
  - "does the AHB HBURST SEQ subordinate pass --verify-hdl?"
  - "how was the AHB dynamic wait WIDTHEXPAND warning resolved?"
  - "what happened to the Verilator WIDTHEXPAND warnings on ahb_lite_subordinate_byte_lane_hburst_seq?"
  - "is --verify-hdl a clean gate for the AHB HBURST SEQ family now?"
  - "why does an AHB arithmetic mask require missing literal intent?"
date: 2026-11-02
status: current
tags: [ial2, ahb, hburst, seq, verify-hdl, verilator, widthexpand, finding]
evidence: ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif; ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/2297-scalar-literal-guard-emission.t; ./bin/fsmgen --quiet --strict --verify-hdl ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif; ./bin/fsmgen --quiet --strict --verify-hdl ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif; ./bin/fsmgen --quiet --strict --verify-hdl ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ppif
---

`.794`: base/BUSY-park four-bit wait versus `1'b1` WIDTHEXPAND fixed,
not BUSY regression. Paired BUSY uses sampled-width one-cycle repeats,
zero compare/bypass, nonzero delay; generic ISF/APB unchanged. That epoch
qualified all three `--verify-hdl` routes above.

Full10: T1490-1492 fail;1493 partial. Selector demanded bitwise-only proof
for uncaptured arithmetic `(& (+ addr_q 1) 32'h3)`. Nov2 `.23.1` fixes
both orders; installed/published literal intent still requires proof after
holder/opcode edits. T2297/2268/2296 and public strict check pass; other
semantic/HDL/full paths await `.26/.13`. Source/RED/focused receipts:
`docs/audits/push-readiness-20261025/` full10-intake/hburst-selector-*.
Book11a retains guards. Support remains unchanged.
