---
id: ial2-ahb-requester-exact-three-busy-insertion-readiness-audit
title: Literal-three requester BUSY insertion is runtime-ready on the shipped width-two counter
answers:
  - "is busy-beats 3 ready for an AHB requester public contract?"
  - "did literal three require a wider requester BUSY counter?"
  - "does exact-three requester BUSY survive ready-low and grant-low stalls?"
  - "what did IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT.1 prove?"
  - "what follows the exact-three requester BUSY readiness audit?"
date: 2026-07-29
status: current
tags: [ial2, ahb, requester, busy, exact-three, counter, runtime, readiness, semantics, mcp]
evidence: docs/IAL2_AHB_REQUESTER_EXACT_THREE_BUSY_INSERTION_READINESS_AUDIT.md; docs/tasks/IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT.md; docs/IAL2_POST_TWO_SUBORDINATE_EXACT_TWO_PAIRED_BUSY_ALIAS_NEXT_OWNER_SELECTION.md; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; t/1521-ial2-ahb-requester-two-busy-insert.t; t/1522-ial2-ahb-requester-two-busy-insert-profile-alias.t; docs/book/src/16c-ial2-ahb.md; MEMORY.md
reverify: rg -n '3 -> 2 -> 1 -> 0|59 nested assertions|Final BUSY counter|EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT\.2|no.*lower-layer repair' docs/IAL2_AHB_REQUESTER_EXACT_THREE_BUSY_INSERTION_READINESS_AUDIT.md docs/tasks/IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT.md docs/TASK_TREE.md
---

A same-volume disposable candidate proved literal `(busy-beats 3)` through the
shipped width-two counter without a lower-layer repair. One assertion-enabled
Verilator binary passed continuously-qualified, 32-clock ready-low, and
32-clock grant-low scenarios. Every run observed one BUSY episode, exactly
three qualified BUSY events, internal counter `3 -> 2 -> 1 -> 0`, no stall-time
consumption or BUSY data completion, one resumed pending `SEQ`, four byte
`INCR4` data beats, and zero final counter.

Strict check, schedule, normalized semantic JSON, exact IAL1/IAL0 artifacts,
and real read-only shell-disabled `fsmgen_semantic_introspect` also passed.
Exact-one, exact-two, base, and malformed boundaries remained distinct. The
audit selects proposed `.2` public contract selection; it ships no behavior.
Counts above three, generalized policy/points/status/bursts/signals,
compositions, interconnect repairs, and decision 0020 remain separate.
