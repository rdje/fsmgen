---
id: ahb-hburst-seq-verify-hdl-widthexpand
title: AHB HBURST SEQ subordinate family emits pre-existing Verilator WIDTHEXPAND warnings under --verify-hdl
answers:
  - "why does the AHB HBURST SEQ subordinate fail --verify-hdl?"
  - "does the AHB BUSY-park source regress --verify-hdl versus the shipped HBURST SEQ source?"
  - "what are the Verilator WIDTHEXPAND warnings on ahb_lite_subordinate_byte_lane_hburst_seq?"
  - "is --verify-hdl a clean gate for the AHB HBURST SEQ family?"
date: 2026-07-12
status: current
tags: [ial2, ahb, hburst, seq, verify-hdl, verilator, widthexpand, finding]
evidence: ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif; ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm
reverify: ./bin/fsmgen --quiet --verify-hdl -o /tmp/ahb_shipped.sv ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif 2>&1 | grep -c WIDTHEXPAND; ./bin/fsmgen --quiet --verify-hdl -o /tmp/ahb_bp.sv ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif 2>&1 | grep -c WIDTHEXPAND
---

Running `./bin/fsmgen --verify-hdl` on the shipped
`ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif` (and every source in the
byte-lane HBURST `SEQ` family) emits two Verilator `WIDTHEXPAND` warnings and,
because `--verify-hdl` treats warnings as errors, exits non-zero. The warnings
are on the wait-cycles counter comparison, e.g.
`ahb_lite_byte_lane_hburst_seq_access_wait_2_cnt == 1'b1`: the counter is wider
than the `1'b1` literal, so Verilator flags `Operator EQ expects N bits on the
RHS, but RHS's CONST '1'h1' generates 1 bits`.

This is a **pre-existing, family-wide** characteristic of the generated
wait-counter logic, not a defect introduced by any one source. The `.776`
BUSY-park source
(`ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif`) produces the
identical two warnings — its only functional delta (BUSY excluded from the
`ahb_seq_idle_clear` condition) does not touch the wait-counter, so BUSY-park
introduces no `--verify-hdl` regression.

Consequence: `--verify-hdl` is not a clean gate for the AHB HBURST `SEQ` family
today. The effective gates these sources are expected to pass are
`--strict --check` (pipeline check) and the focused `t/149x` tests. Making
`--verify-hdl` clean would require width-matching the generated wait-counter
comparison literal to the counter width across the AHB subordinate family — a
separate, family-wide cleanup outside any single BUSY/HBURST feature slice.
