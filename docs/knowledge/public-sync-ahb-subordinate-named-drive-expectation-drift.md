---
id: public-sync-ahb-subordinate-named-drive-expectation-drift
title: Four AHB subordinate IAL0 expectations predate named-drive priority masks
answers:
  - "why do t1475 and t1482 fail after named-drive priority shipped?"
  - "which AHB subordinate structural assertions still expect unguarded ERROR drives?"
  - "what does PUBLIC-SYNC-TEST-DRIFT-REPAIR.4 own?"
date: 2026-07-30
status: current
tags: [ial2, ahb, subordinate, ial0, test-drift, named-drive, priority]
evidence: t/1475-ial2-ahb-subordinate.t; t/1482-ial2-ahb-subordinate-byte-lane.t; perl/FSM/Scheduler/ISF/LoweringIR.pm; docs/tasks/PUBLIC-SYNC-TEST-DRIFT-REPAIR.md
reverify: prove -Iperl t/1475-ial2-ahb-subordinate.t t/1482-ial2-ahb-subordinate-byte-lane.t && git log --oneline 1eec6253d..HEAD -- perl/FSM/Scheduler/ISF/LoweringIR.pm
---

Isolated current-HEAD runs fail exactly four structural assertions: lines
69-70 in t1475 and lines 51-52 in t1482 still require unguarded first-ERROR
HRESP and final-ERROR HREADYOUT assignments. Exact repository search finds no
other copies of those old patterns.

Commit `1dbff8fc6`, the sole LoweringIR change after the generated AHB
subordinate arbitration commit `1eec6253d`, extends declared
rule/transaction priority to exact-one-local-caller named drives. The emitted
ERROR-drive assignments therefore carry inverse-winner masks for the existing
AHB phase/retirement priorities. The lowerer behavior is intentional and its
focused named-drive gates are authoritative; pending
`PUBLIC-SYNC-TEST-DRIFT-REPAIR.4` owns synchronization of only the four stale
structural expectations after `.3` commits cleanly.
