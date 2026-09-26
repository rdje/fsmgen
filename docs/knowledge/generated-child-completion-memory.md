---
id: generated-child-completion-memory
title: Generated child joins retain completion until reactivation
answers:
  - "how do generated child joins handle staggered or early done pulses?"
  - "does await_any preserve pending children for a later await_all?"
  - "why can even dynamic wait counts stall after a child join?"
date: 2026-09-27
status: current
tags: [isf, completion, sync, children, runtime]
evidence: perl/FSM/Scheduler/ISF/ChildCompletion.pm; perl/FSM/Scheduler/ISF/LoweringIR.pm; t/1907-composition-module-definition-ownership.t; t/1908-isf-generated-child-completion-memory.t; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME=1 scripts/run_with_ram_guard.sh prove -Iperl t/1907-composition-module-definition-ownership.t t/1908-isf-generated-child-completion-memory.t t/1244-isf-wait-clause-lowering.t
---

ChildCompletion runs after parent/domain state construction and before
assignment-provenance finalization. It allocates private collision-safe seen
registers and combinational live-done OR seen views for generated instances
consumed by sync_all/sync_any. Start clears seen with priority over capture;
reset clears it when an actor reset exists. The child done remains a pulse.
Views preserve the last live-completion exit edge. Raw done_ports metadata
and public top interfaces stay unchanged. Already-materialized sync transition
and dynamic-wait load guards use the same views, including cloned sync states.

Multi-pending await_any observes without clearing the pending set, consistently
through transaction, branch, loop and repeat collection. A later await_all
still drains every outstanding child. Single-pending await_any drains its set.

T1907 proves real generated workers with independent local values and repeated
activation. T1908 drives the standalone scheduled parent's public handshake
ports with independent early/staggered/simultaneous pulses and checks reset,
rearm, collision avoidance, any-then-all and zero/odd dynamic counts. These
are behavioral observations, not source-admission substitutes.

A separate pre-existing dynamic-wait predicate defect is owned immediately by
`.44`: bitwise AND with a multi-bit count makes positive even counts false.
The completion-memory qualification explicitly excludes general count
correctness until that repair passes. Source, emitted predicate and failing
runtime are retained under `.artifacts/completion-memory/`; T1908 with count 4
recreates the failure.
