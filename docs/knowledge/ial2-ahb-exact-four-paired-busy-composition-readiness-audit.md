---
id: ial2-ahb-exact-four-paired-busy-composition-readiness-audit
title: Exact-four requester BUSY composes directly with an assertion-clean parking aggregate
answers:
  - "is exact-four paired AHB BUSY composition implementation-ready?"
  - "does exact-four requester BUSY preserve subordinate parking state?"
  - "what does the exact-four paired BUSY runtime audit prove?"
  - "does exact-four paired BUSY require a lower-layer repair?"
  - "does exact-four paired BUSY support normalized semantic JSON and MCP?"
  - "what support counts are projected for generic exact-four paired AHB?"
date: 2026-07-29
status: current
tags: [ial2, ahb, requester, subordinate, interconnect, busy, exact-four, composition, runtime, readiness, semantics, mcp]
evidence: docs/IAL2_AHB_EXACT_FOUR_PAIRED_BUSY_COMPOSITION_READINESS_AUDIT.md; docs/tasks/IAL2-AHB-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.md; ppif/ahb_requester_busy_insert_four.ppif; ppif/ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; t/1531-ial2-ahb-exact-three-paired-busy-composition.t; t/1535-ial2-ahb-requester-four-busy-insert.t; t/1536-ial2-ahb-requester-four-busy-insert-profile-alias.t; docs/book/src/16c-ial2-ahb.md
reverify: scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 -- prove -Iperl -v t/1531-ial2-ahb-exact-three-paired-busy-composition.t t/1535-ial2-ahb-requester-four-busy-insert.t t/1536-ial2-ahb-requester-four-busy-insert-profile-alias.t
---

A repository-derived one-subordinate candidate selects the shipped
`amba_requester_busy_insert_four`, existing byte-lane/HBURST-SEQ/BUSY-parking
subordinate, and existing interconnect. Strict check, exact 3 IAL1 / 4 IAL0
artifacts, normalized semantic JSON, real read-only shell-disabled MCP, and
public HDL verification pass with unmatched disposable support.

Verilator 5.046 compiles with `--timing` and all generated assertions enabled.
Runtime proves 5 presentations / 4 beats / 1 BUSY episode / 4 qualified BUSY
events / internal `4 -> 3 -> 2 -> 1 -> 0` / 1 resumed `SEQ` / storage
`0x44332211`, with requester, subordinate, and fabric ownership held through
BUSY.

No lower-layer repair or semantic/MCP API change is required. The audit selects
a separate generic public-contract leaf with projected 329 protocol / 370
supported+strict / 53 AHB paths split 27 `.ppif` / 26 `.ahb`. Alias,
two-subordinate exact-four, broader BUSY semantics, HIAL/VIAL, VHDL,
verification generation, scalability implementation, and decision 0020 remain
separate.

Clean audit commit `19772adec1` now activates only the selected `.2` generic
public-contract leaf. Activation changes continuity documentation and no public
or generated behavior.
