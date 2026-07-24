---
id: ial2-ahb-exact-two-paired-busy-composition-contract-selection
title: Exact-two paired AHB BUSY selects one generic three-child public contract
answers:
  - "what exact-two paired AHB BUSY source was selected?"
  - "what will t1523 prove?"
  - "how will exact-two paired BUSY appear in semantic JSON and MCP?"
  - "what are the projected support counts for exact-two paired BUSY?"
  - "does exact-two paired BUSY need another generator?"
date: 2026-07-24
status: current
tags: [ial2, ahb, requester, subordinate, interconnect, busy, exact-two, composition, contract, semantics, mcp]
evidence: docs/IAL2_AHB_EXACT_TWO_PAIRED_BUSY_COMPOSITION_CONTRACT_SELECTION.md; docs/IAL2_AHB_EXACT_TWO_PAIRED_BUSY_COMPOSITION_READINESS_AUDIT.md; docs/tasks/IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.md; ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ppif; ppif/ahb_requester_busy_insert_two.ppif; perl/FSM/Support/RegressionCorpus.pm; t/1513-ial2-ahb-paired-busy-composition.t; t/1521-ial2-ahb-requester-two-busy-insert.t; docs/book/src/16c-ial2-ahb.md
reverify: rg -n 'ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park|t/1523|317|358|fsmgen_semantic_introspect' docs/IAL2_AHB_EXACT_TWO_PAIRED_BUSY_COMPOSITION_CONTRACT_SELECTION.md docs/tasks/IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.md
---

The selected first public source is
`ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif`.
It uses the existing `ahb_tb` three-child architecture and exact requester,
subordinate, interconnect, IAL1, and IAL0 generators. It is not a new generator.

The requester child reports numeric `busy_insertion.beats=2`; the subordinate
and aggregate propagation report `parks_on=[busy]`. Focused t/1523 plus its
testbench will prove one BUSY episode/two qualified events, stable ownership,
one resumed `SEQ`, four clean byte data beats, and storage `32'h44332211`, while
also covering strict check, schedule, normalized semantic JSON, real read-only
MCP, artifacts, and HDL verification.

Projected accounting after the generic implementation is 317 protocol / 358
supported-smoke+strict / 41 AHB IAL2 paths (21 `.ppif`, 20 `.ahb`). The alias,
two-subordinate exact-two shape, broader BUSY policy/counts, selector repair,
and decision 0020 remain separate.
