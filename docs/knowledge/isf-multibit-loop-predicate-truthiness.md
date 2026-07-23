---
id: isf-multibit-loop-predicate-truthiness
title: Bare known-width multi-bit ISF while and until predicates use nonzero truthiness
answers:
  - "how does ISF interpret a multi-bit while condition?"
  - "how does ISF interpret a multi-bit until condition?"
  - "does an ISF loop condition test exactly one or any nonzero value?"
  - "why did the generated AHB requester stall with beats remaining equal to four?"
  - "what does t 1510 prove?"
  - "what shipped in ISF-MULTIBIT-LOOP-PREDICATE-TRUTHINESS-REPAIR.1?"
date: 2026-07-23
status: current
tags: [isf, while, until, loop, truthiness, lowering, ahb, regression]
evidence: perl/FSM/Scheduler/ISF/LoweringIR.pm; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; t/1245-isf-transaction-loop-lowering.t; t/1510-isf-multibit-loop-predicate-truthiness.t; t/1511-ial2-ahb-requester-burst-completion.t; t/data/isf_multibit_loop_predicate_truthiness_tb.svt; t/data/ahb_requester_loop_entry_truthiness_tb.svt; t/data/ahb_requester_burst_completion_tb.svt; docs/ISF_SPEC.md; docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md; docs/book/src/13d-control-flow.md; docs/book/src/13h-lowering-reference.md
reverify: prove -Iperl t/1245-isf-transaction-loop-lowering.t t/1510-isf-multibit-loop-predicate-truthiness.t t/1511-ial2-ahb-requester-burst-completion.t
---

Bare `while` and `until` conditions with a known width greater than one lower
through an explicit width-matched comparison with zero. Thus a three-bit value
from `1` through `7` is true and `0` is false. The same normalized condition is
used at `while` entry and retest and at the body-first `until` check. One-bit
conditions keep their prior compact selector, expression conditions are not
rewritten by this rule, and `transaction_loops[].condition` preserves the
authored text.

The defect was exposed while runtime-probing the pending AHB requester BUSY
insertion source. The shipped requester uses a five-bit bare
`beats_remaining_q` condition. Before this repair, generated HDL treated its
true selector as exact-one and its false selector as zero, leaving value `4`
with no enabled edge. The t/1510 generated-HDL regressions now cover every
three-bit input value and prove the public requester advances from remaining
count `4` to `3` instead of stalling at loop entry.

That first repair also exposed an independent pre-existing requester terminal
beat defect: sequential complementary `when` clauses turned remaining count
`1` into `0` and then `31`. The completed prerequisite `.2` changed the
non-terminal guard to strict `> 1`; t/1511 now proves complete `SINGLE` and
`INCR4` generated-HDL execution. The separate requester completion fact owns
the durable details of that correction.
