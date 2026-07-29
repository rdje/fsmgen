---
id: ial2-ahb-exact-three-paired-busy-composition-readiness-audit
title: Exact-three requester BUSY composes directly with an assertion-clean parking aggregate
answers:
  - "is exact-three paired AHB BUSY composition implementation-ready?"
  - "does exact-three requester BUSY preserve subordinate parking state?"
  - "what does the exact-three paired BUSY runtime audit prove?"
  - "does exact-three paired BUSY require a lower-layer repair?"
  - "will exact-three paired BUSY work through normalized semantic JSON and MCP?"
  - "what support counts are projected for one generic exact-three paired source?"
date: 2026-07-29
status: current
tags: [ial2, ahb, requester, subordinate, interconnect, busy, exact-three, composition, runtime, readiness, semantics, mcp]
evidence: docs/IAL2_AHB_EXACT_THREE_PAIRED_BUSY_COMPOSITION_READINESS_AUDIT.md; docs/tasks/IAL2-AHB-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.md; ppif/ahb_requester_busy_insert_three.ppif; ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; t/1520-ahb-direct-subordinate-pipelined-active-transfer-audit.t; t/1523-ial2-ahb-exact-two-paired-busy-composition.t; t/1525-ial2-ahb-two-subordinate-exact-two-paired-busy-composition.t; t/1528-ial2-ahb-requester-three-busy-insert.t; docs/book/src/16c-ial2-ahb.md
reverify: scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 -- prove -Iperl t/1520-ahb-direct-subordinate-pipelined-active-transfer-audit.t t/1523-ial2-ahb-exact-two-paired-busy-composition.t t/1525-ial2-ahb-two-subordinate-exact-two-paired-busy-composition.t t/1528-ial2-ahb-requester-three-busy-insert.t
---

A repository-derived one-subordinate candidate selects the shipped
`amba_requester_busy_insert_three`, existing byte-lane/HBURST-SEQ/BUSY-parking
subordinate, and existing interconnect. The current path emits exactly three
IAL1 plus four IAL0 artifacts and generated `ahb_tb`, with width-two
`3 -> 2 -> 1 -> 0` requester retirement, child/propagated `parks_on=[busy]`,
and one-hot accepted-subordinate response ownership.

Strict check, schedule, normalized semantic JSON, and real read-only
shell-disabled MCP all pass. Verilator compiles with every selector assertion
enabled and runtime proves 5 presentations / 4 beats / 1 BUSY episode / 3
qualified BUSY events / 1 resumed `SEQ` / storage `0x44332211`. Direct,
exact-two paired one-/two-window, standalone exact-three, and support/capability
owners pass.

No lower-layer repair or new generator/API is required. The audit selects a
separate generic public-contract leaf with projected 323 protocol / 364
supported+strict / 47 AHB paths split 24 `.ppif` / 23 `.ahb`. The alias,
two-subordinate form, broader BUSY semantics, HIAL/VIAL activation, VHDL,
verification generation, and decision 0020 remain separate.

Clean audit commit `c1f3232f9` now activates only the selected `.2` generic
public-contract leaf. Activation changes continuity documentation and no public
or generated behavior.

Completed `.2` now freezes one generic source, exact support/semantic/MCP
identities, assertion-enabled t1531, and projected 323/364/47 accounting, then
selects `.3` data-only implementation. No source ships during contract
selection.
