---
id: ial2-ahb-requester-exact-four-busy-event-behavior
title: Exact-four AHB requester BUSY ships on the generic PPIF surface
answers:
  - "does FSMGen ship exactly four AHB requester BUSY events?"
  - "how do I use busy-beats 4?"
  - "what width is the exact-four requester BUSY counter?"
  - "what does t1535 prove?"
  - "what are the current AHB support counts after exact-four requester BUSY?"
  - "does exact-four requester BUSY support semantic introspection and MCP?"
date: 2026-07-29
status: current
tags: [ial2, ahb, requester, busy, exact-four, ppif, runtime, counter, semantics, mcp]
evidence: docs/IAL2_AHB_REQUESTER_EXACT_FOUR_BUSY_EVENT_BEHAVIOR.md; docs/IAL2_AHB_REQUESTER_EXACT_FOUR_BUSY_EVENT_CONTRACT_SELECTION.md; ppif/ahb_requester_busy_insert_four.ppif; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; perl/FSM/Support/RegressionCorpus.pm; t/1535-ial2-ahb-requester-four-busy-insert.t; t/data/ahb_requester_four_busy_insert_tb.svt; docs/tasks/IAL2-AHB-REQUESTER-EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT.md; docs/book/src/16c-ial2-ahb.md
reverify: scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 -- prove -Iperl -v t/1535-ial2-ahb-requester-four-busy-insert.t
---

`ppif/ahb_requester_busy_insert_four.ppif` ships literal `(busy-beats 4)`
beside `(busy-before-beat 2)`. The bounded public count accepts literal
integers `2..4`; absence remains exact-one and 0/1/5+ or non-literals fail
closed.

The existing requester generator emits `amba_requester_busy_insert_four`
through IAL2 -> IAL1 -> IAL0. Integer-loop minimum-width derivation preserves
width two for exact-two/three and selects width three for exact-four.
Assertion-enabled t1535 observes exact `4 -> 3 -> 2 -> 1 -> 0` retirement in
continuous, 32-clock ready-low, and 32-clock grant-low scenarios, with four
qualified BUSY events, stable pending ownership, one resumed `SEQ`, four data
beats, and zero final count.

Strict/check/schedule/artifact/verifier, normalized semantic JSON, and real
read-only shell-disabled MCP parity pass. Current accounting is 327 protocol /
368 supported+strict / 51 AHB paths split 26 `.ppif` / 25 `.ahb`. The matching
exact-four alias and broader count/policy/composition work remain separate.
