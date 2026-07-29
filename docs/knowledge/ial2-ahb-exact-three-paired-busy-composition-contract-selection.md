---
id: ial2-ahb-exact-three-paired-busy-composition-contract-selection
title: Exact-three paired AHB BUSY selects one generic assertion-enabled public contract
answers:
  - "what exact-three paired AHB BUSY source is selected?"
  - "what will t1531 prove?"
  - "how will exact-three paired BUSY appear in semantic JSON and MCP?"
  - "what support counts are projected for exact-three paired BUSY?"
  - "does exact-three paired BUSY require another generator?"
date: 2026-07-29
status: current
tags: [ial2, ahb, requester, subordinate, interconnect, busy, exact-three, composition, contract, semantics, mcp]
evidence: docs/IAL2_AHB_EXACT_THREE_PAIRED_BUSY_COMPOSITION_CONTRACT_SELECTION.md; docs/IAL2_AHB_EXACT_THREE_PAIRED_BUSY_COMPOSITION_READINESS_AUDIT.md; docs/tasks/IAL2-AHB-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.md; ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif; ppif/ahb_requester_busy_insert_three.ppif; perl/FSM/Support/RegressionCorpus.pm; t/1520-ahb-direct-subordinate-pipelined-active-transfer-audit.t; t/1523-ial2-ahb-exact-two-paired-busy-composition.t; t/1525-ial2-ahb-two-subordinate-exact-two-paired-busy-composition.t; t/1528-ial2-ahb-requester-three-busy-insert.t; docs/book/src/16c-ial2-ahb.md
reverify: rg -n 'ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park|t/1531|323|364|fsmgen_semantic_introspect|without `--no-assert`' docs/IAL2_AHB_EXACT_THREE_PAIRED_BUSY_COMPOSITION_CONTRACT_SELECTION.md docs/tasks/IAL2-AHB-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.md
---

The selected first public source is
`ppif/ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif`.
It reuses the existing three-child `ahb_tb`, exact requester/subordinate/fabric
generators, three IAL1 artifacts, and four IAL0 artifacts. No parser or
generator algorithm changes.

Focused t1531 plus its testbench must prove strict/support/report/artifact,
normalized semantic JSON, real read-only shell-disabled MCP, `--verify-hdl`,
width-two `3 -> 2 -> 1 -> 0`, child/propagated BUSY parking, one-hot fabric
ownership, and assertion-enabled 5/4/1/3/1/`44332211` runtime.

Projected accounting is 323 protocol / 364 supported-smoke+strict / 47 AHB
paths split 24 `.ppif` / 23 `.ahb`. The matching alias, two-subordinate form,
broader BUSY semantics, HIAL/VIAL activation, VHDL, verification generation,
and decision 0020 remain separate.
