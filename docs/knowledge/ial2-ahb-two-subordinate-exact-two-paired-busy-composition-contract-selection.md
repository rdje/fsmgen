---
id: ial2-ahb-two-subordinate-exact-two-paired-busy-composition-contract-selection
title: FSMGen selects a topology-first generic identity for two-subordinate exact-two paired AHB BUSY
answers:
  - "what public source is selected for two-subordinate exact-two paired AHB BUSY?"
  - "why is the two-subordinate exact-two AHB source name topology-first?"
  - "what does IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.7 select?"
  - "what will t 1525 prove?"
  - "what are the projected support counts after two-subordinate exact-two paired BUSY?"
  - "will the new two-subordinate exact-two source have MCP semantic introspection?"
date: 2026-07-24
status: current
tags: [ial2, ahb, requester, subordinate, interconnect, busy, exact-two, composition, contract, semantic, mcp]
evidence: docs/IAL2_AHB_TWO_SUBORDINATE_EXACT_TWO_PAIRED_BUSY_COMPOSITION_CONTRACT_SELECTION.md; docs/IAL2_AHB_TWO_SUBORDINATE_EXACT_TWO_PAIRED_BUSY_COMPOSITION_READINESS_AUDIT.md; ppif/ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park.ppif; ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif; docs/tasks/IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.md
reverify: bash knowledge-map/scripts/check_knowledge_map.sh
---

`IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.7` selects future
generic source
`ppif/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif`.
Topology-first naming avoids ambiguous `...two_two_subordinate...`: the first
phrase names the two-subordinate aggregate and the second names exact-two
requester BUSY cardinality. No existing source is renamed.

The source reuses the four-child `ahb_tb`, exact-two requester, status/control
BUSY-parking subordinates, interconnect, `[0,4)`/`[4,8)` windows, exact four
IAL1/five IAL0 artifacts, numeric `before_beat=2`/`beats=2`, both child and
propagated `parks_on=[busy]`, and retained one-hot response ownership. A
reserved-name strict/schedule/real read-only MCP probe passes with top/four
children and truthful unmatched support before implementation.

Proposed `.8` will add the generic source/support/t1525/docs only, moving
318/359/42 to 319/360/43 with 22 generic `.ppif` and 21 `.ahb`. t1525 must
lock strict, schedule, normalized semantic JSON, real read-only MCP, artifacts,
verification, and one two-command runtime totaling four qualified BUSY events,
two resumed SEQ events, eight data beats, and final status/control storage
`44332211`/`88776655`. A matching `.ahb` alias remains separate.
