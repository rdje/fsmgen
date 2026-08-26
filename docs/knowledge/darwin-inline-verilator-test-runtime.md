---
id: darwin-inline-verilator-test-runtime
title: Legacy generated-Verilator tests use one bounded test-only supervisor
answers:
  - "how are legacy generated Verilator test executables supervised?"
  - "why does standard Darwin CI skip inline Verilator runtimes?"
  - "which tests migrate to the bounded Verilator test runtime?"
  - "does the legacy Verilator test supervisor replace the VIAL lifecycle?"
  - "how should t296 resume after a RAM guard interruption?"
  - "does t296 support checkpointed corpus-matrix recovery?"
  - "can an interrupted uncheckpointed t296 run be resumed?"
date: 2026-08-26
status: current
tags: [verilator, tests, runtime, darwin, process-supervision, qualification]
evidence: >-
  docs/decisions/0086-legacy-verilator-tests-use-one-bounded-test-runtime-supervisor.md;
  docs/decisions/0087-test-subprocesses-use-shared-mechanism-and-sealed-policy-adapters.md;
  docs/tasks/DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.md;
  docs/book/src/16dc-vial-portable-verilator-runtime-measurement.md;
  t/lib/FSM/Test/ProcessSupervisor.pm;
  t/lib/FSM/Test/VerilatorRuntime.pm;
  t/data/darwin_inline_verilator_runtime_manifest.json;
  t/1668-darwin-inline-verilator-test-runtime.t;
  t/296-regression-corpus-supported-behavior.t;
  t/lib/FSM/Test/T296Checkpoint.pm;
  t/1597-t296-checkpoint.t;
  t/1498-ial2-ahb-requester-busy-insert.t;
  t/1559-vial-ahb-runtime-parity.t
reverify: >-
  prove -Iperl -It/lib t/1597-t296-checkpoint.t
  t/1668-darwin-inline-verilator-test-runtime.t &&
  rg -n --glob 't/*.t' 'run_verilator_(?:compile|version)|run_generated_binary' t &&
  ! rg -n --glob 't/*.t' 'command\\s*=>\\s*\\[\\s*\\$binary(?:\\s*,|\\s*\\])' t
---

The pre-migration legacy surface contained 37 literal `verilator --binary`
compile calls and 37 matching generated-runtime calls across 34 test files.
Thirty-six runtime calls in 33 files used `IPC::Cmd::run` without a timeout.
The remaining direct baseline in `t/1559` used a 30-second `IPC::Cmd` alarm
timeout without whole-process-group cleanup. None had a pre-discovery Darwin
guard. The owning task and closed tracked test manifest retain that exact
per-path inventory and independent compile/runtime file-set comparison.

Decision `0086` is implemented by test-only
`FSM::Test::VerilatorRuntime`. It owns version, compile, and runtime processes
at the existing qualified
10/120/30-second walls and 65,536/8,388,608/67,108,864-byte capture limits.
It uses scalar argv only, a close-on-exec handoff channel, separate bounded
stdout/stderr, monotonic timing, one process group, TERM/KILL escalation,
leader reaping, and verified group disappearance. Timeout, capture overflow,
signal, nonzero exit, handoff failure, or cleanup failure stays failed; there
is no retry. All 37 compile and 37 generated-runtime callsites in the exact
34-file set are helper-owned, and no direct generated-binary IPC launch
remains.

Standard Darwin execution of the affected surface is explicit through
`FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME=1`. The caller emits its TAP skip before
tool discovery, and the helper independently refuses an unqualified Darwin
process before `fork`/`exec`. Non-Darwin execution and every existing
generated-HDL/testbench/oracle remain unchanged. The focused hostile watcher
validates the closed census manifest, independently scans the tracked tests,
rejects new unbounded direct paths, and proves overflow, timeout, surviving-
descendant, exec, signal, nonzero, guard, environment, and cleanup behavior.

Decision `0087` later extracted the unchanged process mechanics into private
`FSM::Test::ProcessSupervisor` so another bounded test domain could reuse them.
`FSM::Test::VerilatorRuntime` remains the only policy owner for this surface:
its schema, Darwin guard, stage admission, fixed bounds, path checks, and
observable behavior are unchanged. A focused watcher rejects direct low-level
use by non-policy helper modules.

This is verification-test process supervision, not IASIM execution and not a
new FSMGEN execution profile. It neither exposes nor replaces the private
`FSM::VIAL::Backend::VerilatorLifecycle`; existing VIAL public, diagnostic,
and measurement guards remain under decisions `0083`-`0085`.

The long `t/296` corpus matrix has a separate opt-in continuity contract.
Set `FSMGEN_T296_CHECKPOINT` to a safe relative
`.artifacts/t296/<safe-name>.json` path before starting it under the RAM guard.
Only green isolated batches completed after checkpointing was enabled receive
credit. The checkpoint rejects a dirty or different revision, another volume,
symlinks, malformed state, and another contract version; it is removed only
after the complete parent passes. An uncheckpointed interruption has no
reconstructable credit and must restart t296. A host-pressure interruption may
resume the exact command with the same checkpoint after headroom returns; it
does not justify raising either RAM ceiling or weakening the matrix.
