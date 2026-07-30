---
id: ial2-ahb-requester-exact-three-busy-event-behavior
title: Exact-three AHB requester BUSY ships on the generic PPIF surface
answers:
  - "does FSMGen ship exactly three AHB requester BUSY events?"
  - "how do I use busy-beats 3?"
  - "what generates amba_requester_busy_insert_three?"
  - "what does t1528 prove?"
  - "what are the current AHB support counts after exact-three requester BUSY?"
  - "does exact-three requester BUSY support semantic introspection and MCP?"
date: 2026-07-29
status: current
tags: [ial2, ahb, requester, busy, exact-three, ppif, runtime, counter, semantics, mcp]
evidence: docs/IAL2_AHB_REQUESTER_EXACT_THREE_BUSY_EVENT_BEHAVIOR.md; docs/IAL2_AHB_REQUESTER_EXACT_THREE_BUSY_EVENT_CONTRACT_SELECTION.md; ppif/ahb_requester_busy_insert_three.ppif; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; perl/FSM/Support/RegressionCorpus.pm; t/1528-ial2-ahb-requester-three-busy-insert.t; t/data/ahb_requester_three_busy_insert_tb.svt; docs/tasks/IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT.md; docs/book/src/16c-ial2-ahb.md
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl -v t/1528-ial2-ahb-requester-three-busy-insert.t
---

`ppif/ahb_requester_busy_insert_three.ppif` now ships literal
`(busy-beats 3)` beside `(busy-before-beat 2)`. The public optional count now
accepts canonical decimal literals `2..16`; absence remains exact-one and
0/1/17+, non-canonical, or non-literal forms fail closed.

The source generates `amba_requester_busy_insert_three` through the existing
requester generator and mandatory IAL2 -> IAL1 -> IAL0 path. The unchanged
width-two actor counter and qualified rules retire `3 -> 2 -> 1 -> 0`.
Assertion-enabled t1528 directly observes that sequence across continuous,
32-clock ready-low, and 32-clock grant-low cases, with one BUSY episode, three
qualified events, stable pending ownership, one resumed `SEQ`, four data
beats, and zero final count.

Strict/check/schedule/artifact/verifier, normalized semantic JSON, and real
read-only shell-disabled MCP parity pass. The matching byte-identical `.ahb`
alias also ships through `.5`, establishing 322/363/46. The generic exact-three
paired source established 323/364/47; its matching alias moves current
checkpoint to 324/365/48. The generic two-subordinate exact-three paired source
established 325/366/49; its matching alias established 326/367/50. The generic
exact-four requester established 327/368/51 and its matching alias established
328/369/52. The later exact-four paired generic/profile pair moves current
accounting to 330 protocol / 371 supported+strict / 54 AHB paths split 27
`.ppif` / 27 `.ahb`.
Focused t1529
proves alias parity without a second simulation and t1528 remains shared. Fact
`ial2-ahb-requester-exact-three-busy-event-profile-alias-behavior` owns the
alias surface; broader count/policy/composition work remains separate.
Requester aliases and generic/alias one-/two-subordinate exact-two paired
surfaces pass t1512/t1522-t1526; t248+t297 pass 6,899 assertions, and
strengthened t1518 locks current behavior/fact/mdBook truth. The selected
generic one-subordinate exact-three paired readiness audit now passes; its
completed contract selector freezes a separate implementation leaf, but no
exact-three paired public source ships yet.
