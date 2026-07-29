---
id: ial2-ahb-two-subordinate-exact-three-paired-busy-composition-contract-selection
title: FSMGen selects the generic two-window exact-three paired AHB BUSY contract
answers:
  - "what public source is selected for two-subordinate exact-three paired AHB BUSY?"
  - "what will t 1533 prove?"
  - "what are the projected support counts after generic two-window exact-three paired BUSY?"
  - "will the two-window exact-three source have MCP semantic introspection?"
  - "what does IAL2-AHB-TWO-SUBORDINATE-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.2 select?"
date: 2026-07-29
status: current
tags: [ial2, ahb, requester, subordinate, interconnect, busy, exact-three, two-window, composition, contract, semantic, mcp]
evidence: docs/IAL2_AHB_TWO_SUBORDINATE_EXACT_THREE_PAIRED_BUSY_COMPOSITION_CONTRACT_SELECTION.md; docs/IAL2_AHB_TWO_SUBORDINATE_EXACT_THREE_PAIRED_BUSY_COMPOSITION_READINESS_AUDIT.md; docs/tasks/IAL2-AHB-TWO-SUBORDINATE-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.md; ppif/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif; ppif/ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif
reverify: bash knowledge-map/scripts/check_knowledge_map.sh
---

Contract `.2` selects future generic source
`ppif/ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif`
as the exact data-only extension of the shipped two-window exact-two source.
It retains four-child `ahb_tb`, status/control windows, exact 4 IAL1/5 IAL0
artifacts, width-two `3 -> 2 -> 1 -> 0`, requester
`before_beat=2`/`beats=3`, both child/propagated `parks_on=[busy]`, and one-hot
accepted-subordinate response ownership.

Proposed `.3` will add the generic source/support/t1533/docs only, moving
324/365/48 split 24/24 to 325/366/49 split 25 `.ppif`/24 `.ahb`. t1533 owns
strict/check/schedule/artifacts, normalized semantic JSON, real read-only
shell-disabled MCP, public `--verify-hdl`, and assertion-enabled two-command
10/8/2/6/2/status-`44332211`/control-`88776655` runtime with stable selected,
unselected, and fabric state. The matching alias and broader BUSY/HIAL/VIAL/
VHDL/verification-generation work remain separate.
