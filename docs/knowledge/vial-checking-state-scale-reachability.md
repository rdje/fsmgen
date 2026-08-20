---
id: vial-checking-state-scale-reachability
title: VIAL checking-state scale uses packed semantic oracles at each reachable level
answers:
  - "which VIAL checking-state scale levels are reachable?"
  - "how does VIAL prove a scoreboard reaches and drains one million entries?"
  - "how does VIAL prove an exact one million entry coverage hit vector?"
  - "what is the VIAL checking-state coverpoint source boundary?"
  - "what is the VIAL checking-state random occurrence plan boundary?"
  - "why does checking-state scale not use the portable SystemVerilog backend as its oracle?"
  - "does a VIAL cross enumerate explicit tuples or a static Cartesian bin domain?"
  - "what does preflight_dominated mean for checking-state random occurrences?"
date: 2026-08-20
status: current
tags: [vial, checking-state, scale, scoreboard, coverage, faults, randomness]
evidence: >-
  docs/decisions/0073-checking-state-scale-uses-packed-state-oracles-and-static-cross-domains.md;
  docs/decisions/0055-vial-scale-proof-uses-orthogonal-workloads-and-stage-local-oracles.md;
  docs/VIAL_SOURCE_AND_SEMANTIC_IR_V1_CONTRACT.md;
  docs/VIAL_EXECUTION_IR_V1_CONTRACT.md;
  perl/FSM/VIAL/SemanticBuilder.pm; perl/FSM/VIAL/ExecutionBuilder.pm;
  perl/FSM/VIAL/Backend/TraceValidator.pm; perl/FSM/VIAL/Backend/ResultProducer.pm;
  perl/FSM/Support/VIALExecutionContract.pm;
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md;
  docs/book/src/16d-hial-vial-verification-architecture.md
reverify: >-
  rg -n 'checking_state_v1|coverage_bins_and_cross_tuples|random_occurrences|serialized_plan_bytes|cross Cartesian product' docs/decisions/0073-checking-state-scale-uses-packed-state-oracles-and-static-cross-domains.md perl/FSM/VIAL/SemanticBuilder.pm perl/FSM/VIAL/ExecutionBuilder.pm perl/FSM/Support/VIALExecutionContract.pm
---

Decision `0073` selects one outcome for every non-reference level before the
checking-state generator is implemented:

| Axis | Accepted levels | First earlier-cap level |
|---|---|---|
| model instances | 32 / 1,024 / 4,096 | 4,097 at `/models` |
| scalar state cells | 512 / 32,768 / 65,536 | 65,537 at `/models` |
| scoreboard instances | 32 / 1,024 / 4,096 | 4,097 at `/scoreboards` |
| scoreboard capacity | 4,096 / 262,144 / 1,000,000 | 1,000,001 at the semantic capacity bound |
| coverpoints | 256 / 8,192 | 65,536 is envelope-unconstructible |
| bins plus cross tuples | 4,096 / 262,144 / 1,000,000 | 1,000,001 at `/coverage` |
| faults | 32 / 1,024 / 4,096 | 4,097 at `/faults` |
| random occurrences | 1,024 | 32,768 and 65,536 hit plan bytes; 65,537 hits its count cap |

The coverpoint route accepts 9,524 declarations in 1,048,467 source bytes and
rejects 9,525 in 1,048,577 bytes at the 1,048,576-byte parser cap. Selected
65,536/65,537 sources cross the scale constructor's 1,114,112-byte envelope,
so decision `0072` requires an `envelope_unconstructible` result plus the
separate measured 9,524/9,525 product boundary.

Compact Boolean random sources parse at all selected levels. The exact plan
route accepts 8,440 occurrences in 16,775,415 bytes and rejects 8,441 at the
16,777,216-byte serialized-plan cap. The full 32,768 qualification returns the
same `/plan` diagnostic. The million-level scoreboard proof therefore cannot
be represented as one operation per enqueue; it uses the qualification-only
packed-state evaluator instead.

That evaluator consumes caller-sealed canonical SemanticIR and ExecutionIR. A
one-million-entry scoreboard stores only its varying 32-bit payload in a
4,000,000-byte packed FIFO, compares every reconstructed complete transaction,
reaches exact maximum depth 1,000,000, and drains to zero. Coverage uses one bit
per static bin or tuple, so an exact million-entry hit vector occupies 125,000
bytes and can be byte-compared without a million JSON records.

VIAL v1 has no tuple-list syntax. An explicitly authored `cross` names its
points, and the Cartesian product of those points' explicitly authored bins is
the complete static tuple domain required by the older source/execution
contracts and current builders. No backend may create an undeclared bin, cross,
or tuple outside that domain. Two 999-bin points plus their 998,001-tuple cross
and one independent bin make exactly 1,000,000 entries in a 62,841-byte source;
one sample hits the exact all-one vector because every authored bin matches.

`TraceValidator`, `ResultProducer`, and the first portable SystemVerilog backend
remain result/profile machinery, not general checking-state semantic oracles.
This selection changes no product behavior, support state, performance budget,
or capacity claim. Implementation is owned separately by
`HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.5.2`.
