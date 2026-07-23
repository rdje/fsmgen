---
id: ial2-ahb-requester-wrap-progression-repair
title: AHB requester fixed wrapping bursts advance through the wrap base
answers:
  - "does the generated AHB requester WRAP4 progression work?"
  - "what address sequence does byte WRAP4 starting at 3 produce?"
  - "how was the AHB requester WRAP boundary skip repaired?"
  - "does the AHB requester support WRAP8 and WRAP16 progression?"
  - "are generated and direct AHB requester wrap algorithms aligned?"
date: 2026-07-23
status: current
tags: [ial2, ahb, requester, wrap, generated-hdl, correctness, repair]
evidence: docs/IAL2_AHB_REQUESTER_WRAP_PROGRESSION_REPAIR.md; docs/IAL2_AHB_REQUESTER_WRAP_PROGRESSION_RUNTIME_AUDIT.md; docs/tasks/IAL2-AHB-REQUESTER-WRAP-PROGRESSION-AUDIT.md; ppif/ahb_requester.ppif; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; fsm/amba_requester.fsm; t/1517-ial2-ahb-requester-wrap-progression-audit.t; t/data/ahb_requester_wrap_progression_audit_tb.svt; t/310-systemverilog-implicit-width-and-truthiness-hardening.t; docs/book/src/16c-ial2-ahb.md; docs/book/src/14-feature-backlog.md; docs/TASK_TREE.md; MEMORY.md
reverify: prove -Iperl t/1517-ial2-ahb-requester-wrap-progression-audit.t
---

The public generated requester and direct seed increment `addr_q` first, then
replace an incremented value equal to `wrap_high_q` with `wrap_base_q`. This
avoids the old mutation/retest sequence that skipped the base address.

Generated-HDL t/1517 proves byte/halfword/word WRAP4 plus byte WRAP8/WRAP16.
Representative accepted addresses are byte WRAP4 start `3` -> `3,0,1,2`,
halfword WRAP4 start `6` -> `6,0,2,4`, and word WRAP4 start `12` ->
`12,0,4,8`. Public contracts, ports, reports, support accounting, artifacts,
non-wrap progression, and the existing paired BUSY INCR4 behavior remain
unchanged.
