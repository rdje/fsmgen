---
id: isf-constant-guard-emission
title: ISF literal guards retain false predicates and unambiguous numeric carriers
answers:
  - "how do literal zero and one rule and entry guards execute?"
  - "why must numeric guard carriers avoid compact delayed-pulse tokens?"
  - "does reset hide an enabled ISF sample register-input bypass?"
date: 2026-09-27
status: current
tags: [isf, guards, emitter, rules, sample, reset]
evidence: perl/FSM/Scheduler/ISF/Emitter/FSM.pm; t/1972-isf-constant-false-guards.t; t/data/isf_constant_false_guards.isf; docs/book/src/13g-rules.md; docs/book/src/13b-transactions.md
reverify: scripts/run_with_ram_guard.sh prove -Iperl t/1972-isf-constant-false-guards.t; qualify the Darwin runtime explicitly before enabling FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME=1. A runtime skip is not runtime evidence.
---

At bbb1ed7352255345722939a6e5a029dabd64055a, a strict-admitted rule with
(when 0) retained port=0 in LoweringIR but became an unconditional DT because
Emitter::FSM::_format_guard_suffix used Perl truthiness as a presence test.
The same mistake removed the false inline-sample guard and entry transition.
A valid (when 1 (sample data as captured)) entry also exposed a numeric guard
syntax collision: the compact <1 group head was parsed as a delayed pulse.

Presence checks now preserve scalar zero. Numeric guard tokens are emitted as
explicit boolean expressions, for example < (!= 0 0), in DT headers, assignment
suffixes and nested groups. This also avoids strict infix classification of
compact numeric DT headers or a bare numeric nested payload before an assignment.
True port=1 assignment/header guards keep their existing elision. Symbolic and
relational guards retain their meaning; state bookkeeping remains separate.

T1972 first failed against the predecessor: both HDL targets wrote disabled=5,
captured=42 and observed=9 despite false guards. The corrected public-pin oracle
keeps disabled/captured/observed at zero for the false entry; true-entry and
symbolic controls still execute. Independent reset/repeated-activation controls,
actual carrier parsing, detached IR and complete native/API/newline reports
qualify the carrier/report boundary. Verilog false/true entry and SystemVerilog
false entry pass runtime; SystemVerilog true entry remains blocked before exec
by pid=43538 setpgid undef errno=1 (Operation not permitted). The owner below
links the existing native containment repair; no retry establishes its cause.
A synthetic rule assignment group covers the numeric group
rendering without claiming that shape originates from every current producer.

A sample uses register-input semantics. Its visible name is the input mux, so an
enabled entry sample can expose data during reset even though the hidden storage
register is reset. The runtime oracle checks that distinction rather than
requiring the visible bypass output to equal the reset value. This is existing
behavior, not a reset contract change.

Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2.2.1.
Re-derivation uses actual IR/carrier and public report paths; falsification is
the predecessor RED plus true/symbolic/reset controls through generated HDL;
durability is the tracked fixture, T1972, emitter, book and owning task.
