---
id: ial2-ahb-requester-exact-two-busy-event-contract-selection
title: Exact-two AHB requester BUSY uses an optional literal busy-beats 2 clause
answers:
  - "what syntax is selected for exactly two AHB requester BUSY events?"
  - "what does busy-beats 2 mean?"
  - "what did IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.4 select?"
  - "will exact-two BUSY change the existing single BUSY source?"
  - "what source will first ship exact-two requester BUSY?"
  - "how will the exact-two AHB BUSY counter work?"
date: 2026-07-24
status: current
tags: [ial2, ahb, requester, busy, htrans, cardinality, exact-two, contract, ppif]
evidence: docs/IAL2_AHB_REQUESTER_EXACT_TWO_BUSY_EVENT_CONTRACT_SELECTION.md; docs/IAL2_AHB_REQUESTER_MULTI_BUSY_INSERTION_READINESS_AUDIT.md; docs/IAL2_AHB_REQUESTER_SINGLE_BUSY_EVENT_CARDINALITY_REPAIR.md; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; t/1498-ial2-ahb-requester-busy-insert.t; docs/tasks/IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.md
reverify: rg -n 'busy-beats 2|ahb_busy_remaining_q|ahb_requester_busy_insert_two|t/1521|IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT\.5' docs/IAL2_AHB_REQUESTER_EXACT_TWO_BUSY_EVENT_CONTRACT_SELECTION.md docs/tasks/IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.md
---

The first public multiple-BUSY extension is selected as an optional literal
`(busy-beats 2)` beside existing `(busy-before-beat 2)`. Absence remains the
canonical exact-one spelling. The selected parser accepts only literal two and
rejects zero, one, larger values, non-literals, missing insertion/BUSY
prerequisites, and duplicates.

The first additive generic source is
`ppif/ahb_requester_busy_insert_two.ppif`, actor/module
`amba_requester_busy_insert_two`, support ID
`intent.ppif_ahb_requester_busy_insert_two`. Its report uses numeric
`busy_insertion.beats=2`; existing exact-one reports retain string `single`.

A width-two actor-owned `ahb_busy_remaining_q` is initialized to two before
BUSY becomes visible. Each `HGRANT && HREADY && HTRANS==BUSY` event decrements
it; the final event clears it and hands the same transfer to existing
address-pending `SEQ` ownership. Ready/grant stalls do not consume count. `.5`
implemented the contract. It corrected the originally described transaction
local to actor-owned storage for concurrent-rule visibility and added an
explicit final-over-nonfinal rule priority required by the conflict checker;
public semantics are unchanged. Aliases, paired exact-two sources, generalized
counts, policy/runtime behavior, and decision 0020 remain deferred.
