---
id: ial2-ahb-requester-exact-four-busy-event-contract-selection
title: Exact-four requester BUSY contract selects literal range 2..4 and minimum-width lowering
answers:
  - "what public contract follows the exact-four requester BUSY readiness audit?"
  - "what identity will ahb_requester_busy_insert_four use?"
  - "how will FSMGEN preserve exact-two and exact-three counter widths when adding exact four?"
  - "what support counts will the generic exact-four requester project?"
  - "what does IAL2-AHB-REQUESTER-EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT.2 select?"
date: 2026-07-29
status: current
tags: [ial2, ahb, requester, busy, exact-four, contract, counter, support]
evidence: docs/IAL2_AHB_REQUESTER_EXACT_FOUR_BUSY_EVENT_CONTRACT_SELECTION.md; docs/IAL2_AHB_REQUESTER_EXACT_FOUR_BUSY_INSERTION_READINESS_AUDIT.md; docs/tasks/IAL2-AHB-REQUESTER-EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT.md; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1528-ial2-ahb-requester-three-busy-insert.t; docs/book/src/16c-ial2-ahb.md; MEMORY.md
reverify: rg -n 'literal integer in 2\.\.4|ahb_requester_busy_insert_four|_counter_width|327|368|26 \.ppif / 25 \.ahb|t/1535|EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT\.3' docs/IAL2_AHB_REQUESTER_EXACT_FOUR_BUSY_EVENT_CONTRACT_SELECTION.md docs/tasks/IAL2-AHB-REQUESTER-EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT.md docs/TASK_TREE.md
---

The no-behavior contract selects one additive generic
`ppif/ahb_requester_busy_insert_four.ppif` source with actor/module
`amba_requester_busy_insert_four`, support id
`intent.ppif_ahb_requester_busy_insert_four`, and projected accounting
327 protocol / 368 supported+strict / 51 AHB paths split 26 `.ppif` / 25
`.ahb`.

Public normalization will accept only literal counts `2..4`. The generator
will derive minimum unsigned counter width using integer-loop `_counter_width`
semantics: exact two and three remain width two, while exact four uses width
three. Existing qualified rules implement the proven `4 -> 3 -> 2 -> 1 -> 0`
runtime without a lower-layer feature.

Proposed `.3` owns the source, helper use, report/residue truth, t1535
continuous/ready-low/grant-low runtime, semantic/read-only-MCP/artifact/support
gates, preservation, cleanup, and rollback. The matching alias, counts above
four, generalized policy, HIAL/VIAL, VHDL, and verification generation remain
separate.
