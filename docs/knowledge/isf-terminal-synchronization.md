---
id: isf-terminal-synchronization
title: A trailing ISF synchronization holds without inventing a continuation
answers:
  - "can an ISF transaction end with await_all or await_any?"
  - "does a terminal join rearm the parent transaction?"
  - "why did a trailing await_all emit an undefined transition target?"
date: 2026-09-27
status: current
tags: [isf, synchronization, completion, control-flow, reset]
evidence: perl/FSM/Scheduler/ISF/LoweringIR.pm; perl/FSM/Scheduler/ISF/Emitter/FSM.pm; t/1922-isf-terminal-synchronization.t; t/1908-isf-generated-child-completion-memory.t
reverify: FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME=1 scripts/run_with_ram_guard.sh prove -Iperl t/1922-isf-terminal-synchronization.t t/1908-isf-generated-child-completion-memory.t
---

LoweringIR::_link_states previously gave sync_all/sync_any a transition only
when a successor existed. Emitter::FSM::_emit_transitions always consumed the
first target when rendering those states. A trailing join therefore warned
about an undefined target and emitted malformed scheduled source.

Trailing synchronization now gets an explicit self-loop. The normal completion
predicate is retained; an empty pending set emits an unconditional self-loop.
The transaction holds there before and after child completion. It does not
invent a done pulse or an entry transition. An explicit complete after a join
rearms the transaction; reset still restores entry. A self-loop also preserves
a nonempty legal IAL0 state body and keeps completion handoffs represented.

The change affects only synchronization states without an existing successor.
Branch/loop successors and explicit completion retain their prior targets.
Completion-memory capture and live-pulse bypass remain unchanged.

T1922 checks empty, single and multiple pending sets for both forms, warning-free
strict replay of emitted modules, exact system/data interfaces and complete
native/API/newline reports. Its independent parent-handoff model supplies
non-overlapping completion pulses, checks no new activation after later start
requests and proves reset reactivation. T1908 retains continued-join timing,
completion-before-entry, repeated activation and partial-completion reset
controls. This does not repair independent direct transaction controllers.

Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.1.
