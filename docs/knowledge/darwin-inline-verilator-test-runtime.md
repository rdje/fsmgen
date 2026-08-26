---
id: darwin-inline-verilator-test-runtime
title: Legacy generated-Verilator tests use one bounded test-only supervisor
answers:
  - "how are legacy generated Verilator test executables supervised?"
  - "why does standard Darwin CI skip inline Verilator runtimes?"
  - "which tests migrate to the bounded Verilator test runtime?"
  - "does the legacy Verilator test supervisor replace the VIAL lifecycle?"
date: 2026-08-26
status: current
tags: [verilator, tests, runtime, darwin, process-supervision, qualification]
evidence: >-
  docs/decisions/0086-legacy-verilator-tests-use-one-bounded-test-runtime-supervisor.md;
  docs/tasks/DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.md;
  docs/book/src/16dc-vial-portable-verilator-runtime-measurement.md;
  t/1498-ial2-ahb-requester-busy-insert.t;
  t/1559-vial-ahb-runtime-parity.t
reverify: >-
  rg -n --glob 't/*.t' "'verilator',\\s*'--binary'" t &&
  rg -n --glob 't/*.t' 'command\\s*=>\\s*\\[\\s*\\$binary(?:\\s*,|\\s*\\])' t &&
  rg -n 'FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME|VerilatorRuntime'
  docs/decisions/0086-legacy-verilator-tests-use-one-bounded-test-runtime-supervisor.md
  docs/tasks/DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.md
---

The tracked legacy surface contains 37 literal `verilator --binary` compile
calls and 37 matching generated-runtime calls across 34 test files. Thirty-six
runtime calls in 33 files use `IPC::Cmd::run` without a timeout. The remaining
direct baseline in `t/1559` uses a 30-second `IPC::Cmd` alarm timeout but does
not prove whole-process-group cleanup. None has a pre-discovery Darwin guard.
The owning task retains the exact per-path inventory and its independent
compile/runtime file-set comparison.

Decision `0086` selects a test-only `FSM::Test::VerilatorRuntime` helper. It
will own version, compile, and runtime processes with the existing qualified
10/120/30-second walls and 65,536/8,388,608/67,108,864-byte capture limits.
It will use scalar argv only, a close-on-exec handoff channel, separate bounded
stdout/stderr, monotonic timing, one process group, TERM/KILL escalation,
leader reaping, and verified group disappearance. Timeout, capture overflow,
signal, nonzero exit, handoff failure, or cleanup failure stays failed; there
is no retry.

Standard Darwin execution of the affected surface is explicit through
`FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME=1`. The caller emits its TAP skip before
tool discovery, and the helper independently refuses an unqualified Darwin
process before `fork`/`exec`. Non-Darwin execution and every existing
generated-HDL/testbench/oracle remain unchanged. A source watcher rejects new
unbounded direct paths.

This is verification-test process supervision, not IASIM execution and not a
new FSMGEN execution profile. It neither exposes nor replaces the private
`FSM::VIAL::Backend::VerilatorLifecycle`; existing VIAL public, diagnostic,
and measurement guards remain under decisions `0083`-`0085`.
