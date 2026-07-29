---
id: ial2-ahb-two-subordinate-exact-three-paired-busy-composition-readiness-audit
title: Two-window exact-three paired AHB BUSY composition is assertion-clean and contract-ready
answers:
  - "is two-subordinate exact-three paired AHB BUSY composition implementation-ready?"
  - "does exact-three requester BUSY preserve both subordinate windows?"
  - "what does the two-window exact-three paired BUSY runtime prove?"
  - "does two-window exact-three BUSY require a lower-layer repair?"
  - "does two-window exact-three BUSY work through normalized semantic JSON and MCP?"
  - "what support counts are projected for the generic two-window exact-three paired source?"
date: 2026-07-29
status: current
tags: [ial2, ahb, requester, subordinate, interconnect, busy, exact-three, two-window, composition, runtime, readiness, semantics, mcp]
evidence: docs/IAL2_AHB_TWO_SUBORDINATE_EXACT_THREE_PAIRED_BUSY_COMPOSITION_READINESS_AUDIT.md; docs/tasks/IAL2-AHB-TWO-SUBORDINATE-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.md; ppif/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif; ppif/ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; t/1525-ial2-ahb-two-subordinate-exact-two-paired-busy-composition.t; t/1531-ial2-ahb-exact-three-paired-busy-composition.t; docs/book/src/16c-ial2-ahb.md
reverify: scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 -- prove t/1525-ial2-ahb-two-subordinate-exact-two-paired-busy-composition.t t/1531-ial2-ahb-exact-three-paired-busy-composition.t
---

A repository-derived two-window candidate selects the shipped
`amba_requester_busy_insert_three`, both shipped status/control
HBURST-aware byte-lane BUSY-parking subordinates, and the existing fabric. The
current path emits exactly four IAL1 plus five IAL0 artifacts and generated
`ahb_tb`, with width-two `3 -> 2 -> 1 -> 0` requester retirement, both child
and propagated `parks_on=[busy]`, and one-hot accepted-subordinate ownership.

Strict check, schedule, normalized semantic JSON, real read-only shell-disabled
MCP, and public `--verify-hdl` pass. Verilator compiles with every selector
assertion enabled and runtime proves 10 presentations / 8 beats / 2 BUSY
episodes / 6 qualified BUSY events / 2 resumed `SEQ` events / status
`0x44332211` / control `0x88776655`, including stable selected/unselected
endpoint state and fabric ownership.

No lower-layer repair or new generator/API is required. The audit selects a
separate generic public-contract leaf with projected 325 protocol / 366
supported+strict / 49 AHB paths split 25 `.ppif` / 24 `.ahb`. The matching
alias, broader BUSY semantics, generic priority, HIAL/VIAL activation, VHDL,
verification generation, and decision `0020` remain separate.
