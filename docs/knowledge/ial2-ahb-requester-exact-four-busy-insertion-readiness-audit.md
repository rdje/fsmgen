---
id: ial2-ahb-requester-exact-four-busy-insertion-readiness-audit
title: Literal-four requester BUSY insertion is runtime-ready with a minimum-width three-bit counter
answers:
  - "is busy-beats 4 ready for an AHB requester public contract?"
  - "what counter width does exact-four requester BUSY insertion need?"
  - "why should exact-four use minimum-width derivation instead of hardcoded width three?"
  - "does exact-four requester BUSY survive ready-low and grant-low stalls?"
  - "what did IAL2-AHB-REQUESTER-EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT.1 prove?"
date: 2026-07-29
status: current
tags: [ial2, ahb, requester, busy, exact-four, counter, runtime, readiness]
evidence: docs/IAL2_AHB_REQUESTER_EXACT_FOUR_BUSY_INSERTION_READINESS_AUDIT.md; docs/tasks/IAL2-AHB-REQUESTER-EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT.md; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; t/1528-ial2-ahb-requester-three-busy-insert.t; docs/book/src/16c-ial2-ahb.md; MEMORY.md
reverify: rg -n '4 -> 3 -> 2 -> 1 -> 0|ceil\(log2|32 files / 2,510,723 bytes|generated_output.emitted=false|EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT\.2' docs/IAL2_AHB_REQUESTER_EXACT_FOUR_BUSY_INSERTION_READINESS_AUDIT.md docs/tasks/IAL2-AHB-REQUESTER-EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT.md docs/book/src/16c-ial2-ahb.md
---

A repository-local exact-four source still fails closed before generation at
the intentional public literal-`2..3` boundary. A disposable IAL1 candidate
changed only actor identity, `ahb_busy_remaining_q` width `2 -> 3`, and its
initializer `3 -> 4`. It lowered and verified cleanly through IAL0 and
SystemVerilog without changing the existing qualified decrement/final-accept
rules.

One assertion-enabled Verilator 5.046 binary passed continuous, 32-clock
ready-low, and 32-clock grant-low scenarios. Each run observed exactly four
qualified BUSY events, internal `4 -> 3 -> 2 -> 1 -> 0`, stall-time stability,
one resumed pending `SEQ`, four accepted byte `INCR4` data beats, and zero
final counter.

Exact four is therefore lower-layer ready. The public generator should derive
the minimum unsigned width `ceil(log2(busy_beats + 1))`: literals two and three
remain width two, while literal four becomes width three. This preserves prior
generated behavior and avoids a hardcoded family-wide widening. Clean audit
commit `74d91347e` activates contract leaf `.2` for the next no-behavior
decision before implementation.
