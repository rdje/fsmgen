---
id: isf-empty-terminal-state-carriers
title: Empty terminal ISF states emit explicit carrier holds
answers:
  - "can a transaction end with a static wait without complete?"
  - "why did a terminal wait point or phase emit an invalid empty state?"
  - "does a terminal static wait implicitly complete or rearm?"
date: 2026-09-27
status: current
tags: [isf, wait, phase, point, carrier, completion, reset]
evidence: perl/FSM/Scheduler/ISF/Emitter/FSM.pm; t/1940-isf-empty-terminal-state.t; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md; docs/book/src/13b-transactions.md; docs/isf-spec/02-interface-transactions.md
reverify: FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME=1 scripts/run_with_ram_guard.sh prove -Iperl t/1940-isf-empty-terminal-state.t; scripts/run_with_ram_guard.sh prove -Iperl t/1244-isf-wait-clause-lowering.t t/1922-isf-terminal-synchronization.t t/1413-isf-trigger-anchor.t t/1255-isf-schedule-report-golden-matrix.t
---

LoweringIR leaves a terminal static-wait or passive point/phase marker with no
outgoing transition. Emitter::FSM::_emit_states previously emitted that empty
body directly. The strict carrier parser rejected it, rendering the missing
body as undef in its diagnostic; the carrier itself contained no undef token.
The retained raw generated-child reproduction is independent of formal identity
projection. The direct/generated wait, point and phase census has the same cause.

The emitter now renders an otherwise empty state body as an explicit self-loop.
It retains the source state name and graph, adds no register or completion pulse,
and does not invent a return-to-entry edge. Existing assignments and transitions
emit normally. A positive static wait without a continuation remains in its
final state; explicit successors and complete retain their existing behavior.
Zero waits still erase their wait region; dynamic-wait successor policies are
unchanged and are not generalized by this carrier repair.

T1940 qualifies actual direct/generated carriers, unchanged IR snapshots,
empty-body mutation controls, explicit continuations and complete
native/API/newline check/semantic/schedule parity. Independent Verilator
simulations qualify terminal static-wait hold, repeated requests and reset
reactivation through public interfaces, including generated-child storage
handoffs. Runtime qualification requires the explicit Darwin opt-in and an
available provider; skipped runtime checks cannot qualify these observations.
The earlier terminal synchronization repair remains separately qualified in
[terminal synchronization](isf-terminal-synchronization.md).

Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.55. Remaining formal reservation
preflight and module/child/domain closure resume under .49.2.2.3.2.2.2.2-.3.
