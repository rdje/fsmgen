---
id: ial2-ahb-requester-exact-two-busy-event-behavior
title: Exact-two AHB requester BUSY ships on generic PPIF and matching AHB alias
answers:
  - "does FSMGen ship exactly two AHB requester BUSY events?"
  - "how do I use busy-beats 2?"
  - "what source generates amba_requester_busy_insert_two?"
  - "how does the shipped exact-two AHB BUSY counter work?"
  - "what does t1521 prove?"
  - "is there an exact-two AHB profile alias?"
date: 2026-07-24
status: current
tags: [ial2, ahb, requester, busy, htrans, cardinality, exact-two, ppif, runtime]
evidence: docs/IAL2_AHB_REQUESTER_EXACT_TWO_BUSY_EVENT_BEHAVIOR.md; docs/IAL2_AHB_REQUESTER_EXACT_TWO_BUSY_EVENT_PROFILE_ALIAS_BEHAVIOR.md; ppif/ahb_requester_busy_insert_two.ppif; ppif/ahb_requester_busy_insert_two.ahb; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; perl/FSM/Support/RegressionCorpus.pm; t/1521-ial2-ahb-requester-two-busy-insert.t; t/1522-ial2-ahb-requester-two-busy-insert-profile-alias.t; t/data/ahb_requester_two_busy_insert_tb.svt; docs/tasks/IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.md
reverify: scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 -- prove -v t/1521-ial2-ahb-requester-two-busy-insert.t
---

`ppif/ahb_requester_busy_insert_two.ppif` ships optional literal
`(busy-beats 2)` beside `(busy-before-beat 2)`. It generates
`amba_requester_busy_insert_two` through the existing AHB requester generator
and mandatory IAL2-to-IAL1-to-IAL0 pipeline; it is not a new generator.

Actor-owned width-two `ahb_busy_remaining_q` initializes before BUSY is visible.
Only `HGRANT && HREADY && HTRANS==BUSY` consumes count. The first event
decrements; the second clears the counter and hands the unchanged pending
transfer to existing address-pending `SEQ` ownership. Ready/grant stalls consume
no count, BUSY consumes no data beat, and existing exact-one/base sources retain
their generated shapes.

Both requester suffixes report numeric `busy_insertion.beats=2`.
Assertion-enabled t/1521 proves continuous, 32-clock ready-low, and 32-clock
grant-low cases with exactly two qualified BUSY events, direct private-counter
`2 -> 1 -> 0` retirement and stall stability, and four data beats.
Follow-on t/1522 proves that the byte-identical `.ahb` requester alias exposes
the same artifacts and bounded semantic JSON through the real read-only MCP
adapter. The generic one-subordinate exact-two paired source now also ships and
established the 317 protocol / 358 supported+strict / 41 AHB-path checkpoint.
Its matching aggregate alias now ships too. The generic two-subordinate
exact-two sibling and its matching `.ahb` alias also ship with shared runtime
and semantic/MCP proof established 320/361/44. The additive generic exact-three
requester now moves current accounting to 321/362/45 split 23 `.ppif` / 22
`.ahb`; exact-two behavior and identity remain unchanged.
