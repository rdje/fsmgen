---
id: ial2-ahb-subordinate-busy-park-behavior
title: AHB subordinate BUSY-in-burst parking ships as a new (parked-transfer busy) endpoint source
answers:
  - "how does fsmgen implement AHB subordinate BUSY-in-burst parking?"
  - "what does (parked-transfer busy) do in an AHB subordinate .ppif?"
  - "which source ships AHB BUSY-in-burst parking?"
  - "how is the AHB burst context held across an HTRANS=BUSY beat?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.776 ship?"
date: 2026-07-12
status: current
tags: [ial2, ahb, hburst, seq, busy, parking, subordinate, behavior]
evidence: ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/Support/RegressionCorpus.pm; t/1494-ial2-ahb-subordinate-byte-lane-hburst-seq-busy-park.t; docs/IAL2_AHB_SUBORDINATE_BUSY_PARK_CONTRACT_SELECTION.md
reverify: rg -n 'parked_transfer|parked-transfer|_transfer_parks_busy|parks_on' perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm perl/FSM/Adapter/IAL2/PPIF.pm ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif; prove -l t/1494-ial2-ahb-subordinate-byte-lane-hburst-seq-busy-park.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.776` ships
`ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif`, a new additive
endpoint AHB subordinate source (support identity
`intent.ppif_ahb_lite_subordinate_byte_lane_hburst_seq_busy_park`, coverage
`ial2_ppif_ahb_lite_subordinate_byte_lane_hburst_seq_busy_park_pipeline_cli`,
`source_kind: ppif`). It is a copy of the shipped byte-lane HBURST `WRAP4`/`INCR4`
in-word `SEQ` endpoint source with `(ignored-transfer busy)` replaced by the new
`(parked-transfer busy)` clause (keeping `(ignored-transfer idle)`).

Parser: `PPIF.pm::_parse_ahb_subordinate_transfer_block` collects
`(parked-transfer …)` into `parked_transfer`, and
`AhbSubordinate::_normalize_transfer` accepts either the classic
`ignored={idle,busy}` shape or the BUSY-park `ignored={idle}` + `parked={busy}`
shape (any other combination fails closed; parked-busy also fail-closes unless
the transfer selects the HBURST SEQ policy).

Generator (all gated on the parked-busy flag via `_transfer_parks_busy`): the
concurrent `ahb_seq_idle_clear` rule fires on `(== HTRANS 2'b00)` (IDLE) only instead
of `(| idle busy)`, so a BUSY beat leaves the `seq_*` registers unassigned and
the in-word burst context (`seq_valid_q`, `seq_expected_addr_q`, `seq_size_q`,
`seq_write_q`, `seq_hburst_q`, `seq_beats_remaining_q`) holds across the BUSY
beat. The following `SEQ` beat resumes through the existing `seq_ok_base`
validation, which fail-closes a resume whose address/size/write/burst mode drifts
from the armed burst. `_hburst_seq_policy_report` drops `busy` from `clears_on`
and adds `parks_on: [busy]`, and the `ahb_burst_seq_support_deferred` residue
records shipped BUSY-in-burst parking.

The classic non-parking `ahb_lite_subordinate_byte_lane_hburst_seq` source still
clears on BUSY. Focused coverage: `t/1494`. The matching endpoint/aggregate
aliases, aggregate BUSY parking, requester BUSY insertion, and the first paired
generic aggregate have since shipped. Halfword/word burst `SEQ`, wider bursts,
and true boundary-free active-transfer pipelining remain deferred. Fact
[[ahb-hburst-seq-verify-hdl-widthexpand]] records that the former dynamic-wait
`--verify-hdl` warning was resolved by `.794`'s AHB-local counted-wait form.
