---
id: ial2-ahb-exact-two-paired-busy-composition-profile-alias-contract-selection
title: Exact-two paired AHB BUSY selects a data-only matching profile alias contract
answers:
  - "will the exact-two paired AHB BUSY source get an .ahb alias?"
  - "what support identity is selected for the exact-two paired BUSY alias?"
  - "does the exact-two paired BUSY alias require another generator?"
  - "what will t1524 prove?"
  - "will the exact-two paired BUSY alias support semantic JSON and MCP?"
date: 2026-07-24
status: current
tags: [ial2, ahb, requester, subordinate, interconnect, busy, exact-two, composition, alias, contract, semantics, mcp]
evidence: docs/IAL2_AHB_EXACT_TWO_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_CONTRACT_SELECTION.md; docs/IAL2_AHB_EXACT_TWO_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md; ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; t/1514-ial2-ahb-paired-busy-composition-profile-alias.t; t/1522-ial2-ahb-requester-two-busy-insert-profile-alias.t; t/1523-ial2-ahb-exact-two-paired-busy-composition.t; docs/tasks/IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.md
reverify: rg -n 'candidate.ahb|matched=false|318/359|t/1524|fsmgen_semantic_introspect' docs/IAL2_AHB_EXACT_TWO_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_CONTRACT_SELECTION.md docs/tasks/IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.md
---

The selected follow-on is a byte-identical
`ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ahb`
alias over the shipped generic source. A disposable reserved-suffix probe
strict-checked with `ahb_tb`, three children, numeric requester `beats=2`, both
BUSY-parking projections, normalized semantic root `top`, and byte-identical
generated review artifacts. Existing suffix handling removed only alias
residue. No parser, generator, semantic API, or MCP repair is required.

Proposed `.5` will add the fixture/support/test/docs at projected 318 protocol /
359 supported+strict / 42 AHB paths split 21/21. Focused t1524 must prove strict
check, schedule, normalized semantic JSON, real read-only MCP, artifacts, and
HDL verification without a second simulation; t1523 remains the shared runtime
proof. This `.4` selection itself changes no shipped behavior.
