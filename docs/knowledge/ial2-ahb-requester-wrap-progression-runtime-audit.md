---
id: ial2-ahb-requester-wrap-progression-runtime-audit
title: Generated AHB requester WRAP progression skips the wrap base at the boundary
answers:
  - "does the generated AHB requester WRAP4 progression work?"
  - "what address sequence does the shipped requester produce for byte WRAP4 starting at 3?"
  - "is the AHB requester WRAP progression defect runtime proven?"
  - "why does the AHB requester skip wrap_base_q?"
  - "which task owns the AHB requester WRAP repair?"
  - "does the requester WRAP bug affect WRAP8 and WRAP16?"
date: 2026-07-23
status: current
tags: [ial2, ahb, requester, wrap, generated-hdl, correctness, bug, audit]
evidence: docs/IAL2_AHB_REQUESTER_WRAP_PROGRESSION_RUNTIME_AUDIT.md; docs/tasks/IAL2-AHB-REQUESTER-WRAP-PROGRESSION-AUDIT.md; ppif/ahb_requester.ppif; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; fsm/amba_requester.fsm; t/1517-ial2-ahb-requester-wrap-progression-audit.t; t/data/ahb_requester_wrap_progression_audit_tb.svt; docs/book/src/16c-ial2-ahb.md; docs/book/src/14-feature-backlog.md; docs/TASK_TREE.md; MEMORY.md
reverify: prove -Iperl t/1517-ial2-ahb-requester-wrap-progression-audit.t
---

Generated-HDL audit t/1517 proves that the public requester currently presents
byte `WRAP4` addresses `3,1,2,3` instead of required `3,0,1,2`. The first
generated decision writes `addr_q=wrap_base_q`; the following numbered state
re-tests the mutated address and overwrites it with
`wrap_base_q+addr_step_q`.

The test is a passing defect-reproduction audit, not a declaration that the
bad sequence is supported. `IAL2-AHB-REQUESTER-WRAP-PROGRESSION-AUDIT.2` owns
the repair and must convert t/1517 into a correctness regression. The common
progression block serves WRAP4/8/16, so the root cause applies structurally to
all fixed wrapping modes. Incrementing modes and the existing paired BUSY
INCR4 proofs are unaffected by this specific defect.
