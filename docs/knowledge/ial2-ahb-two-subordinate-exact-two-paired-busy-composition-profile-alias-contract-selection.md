---
id: ial2-ahb-two-subordinate-exact-two-paired-busy-composition-profile-alias-contract-selection
title: Two-subordinate exact-two paired AHB BUSY selects its matching profile alias
answers:
  - "what follows the generic two-subordinate exact-two paired AHB BUSY source?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.810 select?"
  - "what is the selected two-subordinate exact-two paired AHB alias path?"
  - "what will t 1526 prove?"
  - "does the selected alias require a new generator or MCP API?"
  - "what are the projected counts after the two-subordinate exact-two alias?"
date: 2026-07-24
status: current
tags: [ial2, ahb, requester, subordinate, interconnect, busy, exact-two, composition, alias, contract, semantic, mcp]
evidence: docs/IAL2_AHB_TWO_SUBORDINATE_EXACT_TWO_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_CONTRACT_SELECTION.md; docs/IAL2_AHB_TWO_SUBORDINATE_EXACT_TWO_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md; ppif/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif; docs/decisions/0015-ial2-profile-extensions-are-vocabulary-aliases.md; t/1525-ial2-ahb-two-subordinate-exact-two-paired-busy-composition.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
reverify: bash knowledge-map/scripts/check_knowledge_map.sh
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.810` selects proposed `.811` data-only
implementation of byte-identical alias
`ppif/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ahb`.

A disposable reserved-suffix probe passes strict check, schedule, normalized
semantic JSON, and the real read-only `fsmgen_semantic_introspect` adapter with
module `ahb_tb`, root `top`, four children, 29 signals, exact four IAL1/five
IAL0 artifacts, numeric requester `before_beat=2`/`beats=2`, both child and
propagated BUSY parks, retained owner, exact windows, and truthful unmatched
support. Existing suffix handling removes only alias residue; no parser,
generator, semantic model, MCP API, or runtime repair is needed.

Proposed t/1526 will prove byte/report/artifact/strict/semantic/MCP/outdir/
verifier/diagnostic parity without a second simulation; t/1525 remains the
shared runtime. Projected accounting is 320 protocol / 361 supported+strict /
44 AHB paths, split 22 `.ppif` and 22 `.ahb`. Broader behavior and decision
0020 remain separate/inactive.
