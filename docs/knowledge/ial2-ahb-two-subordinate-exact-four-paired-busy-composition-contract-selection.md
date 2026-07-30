---
id: ial2-ahb-two-subordinate-exact-four-paired-busy-composition-contract-selection
title: Two-window exact-four paired AHB BUSY selects one generic assertion-enabled contract
answers:
  - "what two-subordinate exact-four paired AHB BUSY source is selected?"
  - "what will t1539 prove?"
  - "how will two-window exact-four BUSY appear in semantic JSON and MCP?"
  - "what support counts are projected for two-window exact-four AHB BUSY?"
  - "does two-window exact-four AHB BUSY require another generator?"
  - "what is the rollback for two-window exact-four paired AHB BUSY?"
date: 2026-07-30
status: current
tags: [ial2, ahb, requester, subordinate, interconnect, busy, exact-four, two-subordinate, contract, semantics, mcp]
evidence: docs/IAL2_AHB_TWO_SUBORDINATE_EXACT_FOUR_PAIRED_BUSY_COMPOSITION_CONTRACT_SELECTION.md; docs/IAL2_AHB_TWO_SUBORDINATE_EXACT_FOUR_PAIRED_BUSY_COMPOSITION_READINESS_AUDIT.md; docs/tasks/IAL2-AHB-TWO-SUBORDINATE-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.md; ppif/ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif; ppif/ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ppif; perl/FSM/Support/RegressionCorpus.pm; t/1533-ial2-ahb-two-subordinate-exact-three-paired-busy-composition.t; t/1537-ial2-ahb-exact-four-paired-busy-composition.t; docs/book/src/16c-ial2-ahb.md
reverify: rg -n 'ahb_interconnect_two_subordinate_requester_busy_insert_four_byte_lane_hburst_seq_busy_park|t/1539|331|372|fsmgen_semantic_introspect|all assertions' docs/IAL2_AHB_TWO_SUBORDINATE_EXACT_FOUR_PAIRED_BUSY_COMPOSITION_CONTRACT_SELECTION.md docs/tasks/IAL2-AHB-TWO-SUBORDINATE-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.md
---

The selected first public source is
`ppif/ahb_interconnect_two_subordinate_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ppif`.
It reuses the existing four-child/two-window `ahb_tb`, exact requester,
status/control subordinate, and fabric generators, four IAL1 artifacts, and
five IAL0 artifacts. No parser or generator algorithm changes.

Focused t1539 plus its testbench must prove exact source delta, strict/support/
report/artifact behavior, normalized semantic JSON, real read-only shell-
disabled MCP, `--verify-hdl`, width-three `4 -> 3 -> 2 -> 1 -> 0`, two-window
BUSY parking, one-hot fabric ownership, and assertion-enabled
10/8/2/8/2/`44332211`/`88776655` runtime.

Projected accounting is 331 protocol / 372 supported-smoke+strict / 55 AHB
paths split 28 `.ppif` / 27 `.ahb`. The matching alias, counts above four,
broader BUSY semantics, generic priority, HIAL/VIAL, VHDL, verification
generation, portability, scale, and decision `0020` remain separate.

Clean contract commit `4d0cc34bd` activates only selected data-only
implementation `.3`. The source, support entry, t1539, and testbench remain
absent during activation; public accounting stays 330/371/54 split 27/27.

Completed `.3` now ships the selected source, support entry, t1539, and
repository-local assertion-enabled testbench at 331/372/55 split 28 `.ppif`/
27 `.ahb`. Canonical shipped facts live in
`ial2-ahb-two-subordinate-exact-four-paired-busy-composition-behavior`.
