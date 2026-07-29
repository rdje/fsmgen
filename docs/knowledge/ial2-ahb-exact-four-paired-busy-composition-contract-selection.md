---
id: ial2-ahb-exact-four-paired-busy-composition-contract-selection
title: Exact-four paired AHB BUSY selects one generic assertion-enabled public contract
answers:
  - "what exact-four paired AHB BUSY source is selected?"
  - "what will t1537 prove?"
  - "how will exact-four paired BUSY appear in semantic JSON and MCP?"
  - "what support counts are projected for exact-four paired BUSY?"
  - "does exact-four paired BUSY require another generator?"
date: 2026-07-29
status: current
tags: [ial2, ahb, requester, subordinate, interconnect, busy, exact-four, composition, contract, semantics, mcp]
evidence: docs/IAL2_AHB_EXACT_FOUR_PAIRED_BUSY_COMPOSITION_CONTRACT_SELECTION.md; docs/IAL2_AHB_EXACT_FOUR_PAIRED_BUSY_COMPOSITION_READINESS_AUDIT.md; docs/tasks/IAL2-AHB-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.md; ppif/ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif; ppif/ahb_requester_busy_insert_four.ppif; perl/FSM/Support/RegressionCorpus.pm; t/1531-ial2-ahb-exact-three-paired-busy-composition.t; t/1535-ial2-ahb-requester-four-busy-insert.t; t/1536-ial2-ahb-requester-four-busy-insert-profile-alias.t; docs/book/src/16c-ial2-ahb.md
reverify: rg -n 'ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park|t/1537|329|370|fsmgen_semantic_introspect|without `--no-assert`' docs/IAL2_AHB_EXACT_FOUR_PAIRED_BUSY_COMPOSITION_CONTRACT_SELECTION.md docs/tasks/IAL2-AHB-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.md
---

The selected first public source is
`ppif/ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ppif`.
It reuses the existing three-child `ahb_tb`, exact requester/subordinate/fabric
generators, three IAL1 artifacts, and four IAL0 artifacts. No parser or
generator algorithm changes.

Focused t1537 plus its testbench must prove strict/support/report/artifact,
normalized semantic JSON, real read-only shell-disabled MCP, `--verify-hdl`,
width-three `4 -> 3 -> 2 -> 1 -> 0`, child/propagated BUSY parking, one-hot
fabric ownership, and assertion-enabled 5/4/1/4/1/`44332211` runtime.

Projected accounting is 329 protocol / 370 supported-smoke+strict / 53 AHB
paths split 27 `.ppif` / 26 `.ahb`. The matching alias, two-subordinate form,
broader BUSY semantics, HIAL/VIAL activation, VHDL, verification generation,
large-design scale implementation, and decision 0020 remain separate.

Clean contract commit `d54dc8afb` now activates only selected `.3` data-only
implementation. Activation changes continuity documentation and no source,
support entry, test, simulator behavior, or generated behavior.
