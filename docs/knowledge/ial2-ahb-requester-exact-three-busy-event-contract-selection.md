---
id: ial2-ahb-requester-exact-three-busy-event-contract-selection
title: Exact-three AHB requester BUSY extends busy-beats to bounded literals 2 through 3
answers:
  - "what public syntax is selected for exactly three AHB requester BUSY events?"
  - "which busy-beats values will the AHB requester accept after exact-three ships?"
  - "what source will first ship exact-three requester BUSY?"
  - "what does IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT.2 select?"
  - "what support counts are projected for exact-three requester BUSY?"
  - "will exact-three requester BUSY need a wider counter?"
date: 2026-07-29
status: current
tags: [ial2, ahb, requester, busy, exact-three, contract, ppif, counter, semantics, mcp]
evidence: docs/IAL2_AHB_REQUESTER_EXACT_THREE_BUSY_EVENT_CONTRACT_SELECTION.md; docs/IAL2_AHB_REQUESTER_EXACT_THREE_BUSY_INSERTION_READINESS_AUDIT.md; docs/tasks/IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT.md; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; ppif/ahb_requester_busy_insert_two.ppif; t/1521-ial2-ahb-requester-two-busy-insert.t; docs/book/src/16c-ial2-ahb.md; MEMORY.md
reverify: rg -n 'literal integer in 2\.\.3|ahb_requester_busy_insert_three|321|362|23 \.ppif / 22 \.ahb|t/1528|EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT\.3' docs/IAL2_AHB_REQUESTER_EXACT_THREE_BUSY_EVENT_CONTRACT_SELECTION.md docs/tasks/IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT.md docs/TASK_TREE.md
---

The selected exact-three requester extension keeps absence of `busy-beats` as
canonical exact-one and broadens the optional clause from exact literal two to
literal integers `2..3`. Zero, one, values above three, symbolic/non-literal
forms, missing prerequisites, and duplicates fail closed. The selected range
diagnostic names literal integers `2..3`.

The first additive source is
`ppif/ahb_requester_busy_insert_three.ppif`, module
`amba_requester_busy_insert_three`, support ID
`intent.ppif_ahb_requester_busy_insert_three`. It reuses the existing width-two
actor-owned counter and qualified non-final/final rules unchanged; the audit
already proves internal `3 -> 2 -> 1 -> 0` retirement across continuous,
ready-low, and grant-low runtime. Numeric report `beats=3`, truthful exact-one/
two/three residue, normalized semantic/read-only MCP parity, and projected
321/362/45 accounting split 23 generic `.ppif` / 22 `.ahb` are required.

Proposed `.3` owns implementation plus t1528 and strengthened direct t1521
counter observation. The matching exact-three `.ahb` alias, counts above
three, generalized width/policy/points/status, compositions, broader AHB,
AXI/APB/VHDL, and decision 0020 remain separate.
