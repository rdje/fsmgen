---
id: ial2-ahb-requester-burst-completion
title: The AHB requester completes terminal beats without count underflow
answers:
  - "how does the AHB requester finish a burst?"
  - "why did the AHB requester remaining count underflow from zero to 31?"
  - "does the generated AHB requester complete INCR4?"
  - "what does t 1511 prove?"
  - "what shipped in ISF-MULTIBIT-LOOP-PREDICATE-TRUTHINESS-REPAIR.2?"
date: 2026-07-23
status: current
tags: [ial2, ahb, requester, burst, completion, underflow, regression]
evidence: perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; ppif/ahb_requester.ppif; ppif/ahb_requester.ahb; t/1473-ial2-ahb-requester.t; t/1511-ial2-ahb-requester-burst-completion.t; t/data/ahb_requester_burst_completion_tb.svt; docs/IAL2_AHB_REQUESTER_PPIF_BEHAVIOR.md; docs/book/src/16c-ial2-ahb.md; docs/tasks/ISF-MULTIBIT-LOOP-PREDICATE-TRUTHINESS-REPAIR.md
reverify: prove -Iperl t/1473-ial2-ahb-requester.t t/1511-ial2-ahb-requester-burst-completion.t && ./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester.ahb
---

The generated AHB requester uses mutually exclusive terminal and non-terminal
accepted-`OKAY` beat guards. Remaining count `1` sets the count to zero and
clears the active burst; only a count strictly greater than `1` decrements and
advances the beat index, address, and stepped write data.

The strict non-terminal guard repairs a pre-existing sequential-state defect.
The former logically complementary guard re-evaluated after the terminal state
had written zero, became true, and decremented the five-bit count to `31`.
Changing only that guard preserves the public `.ppif` and `.ahb` sources,
ports, report schema, support accounting, and non-terminal progression.

Generated-HDL regression t/1511 runs the public requester through `SINGLE` and
`INCR4`. It proves exact accepted-beat cardinalities of one and four,
respectively; `INCR4` reports indices `0..3`, completes with remaining count
zero, and never visits `31`.
