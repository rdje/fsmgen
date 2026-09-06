---
id: test-subprocess-policy-adapters
title: Test subprocesses share one mechanism behind sealed policy adapters
answers:
  - "how are FSMGen test subprocesses bounded?"
  - "why does t1545 not use IPC Cmd?"
  - "why does the task-acceptance fixture invoke Bash directly?"
  - "who may call the low-level test process supervisor?"
  - "why can T1595 stall before measuring host memory?"
date: 2026-09-06
status: current
tags: [tests, subprocess, supervision, task-acceptance, darwin, locality]
evidence: >-
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md;
  t/1595-agent-runtime-ram-guard-macos-metric.t;
  docs/decisions/0087-test-subprocesses-use-shared-mechanism-and-sealed-policy-adapters.md;
  docs/tasks/DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.md;
  docs/book/src/16dc-vial-portable-verilator-runtime-measurement.md;
  t/lib/FSM/Test/ProcessSupervisor.pm;
  t/lib/FSM/Test/TaskAcceptanceFixtureRuntime.pm;
  t/lib/FSM/Test/VerilatorRuntime.pm;
  t/1545-task-acceptance-doctrine.t;
  t/1668-darwin-inline-verilator-test-runtime.t;
  t/1669-task-acceptance-fixture-runtime.t
reverify: >-
  prove -Iperl -It/lib
  t/1545-task-acceptance-doctrine.t
  t/1668-darwin-inline-verilator-test-runtime.t
  t/1669-task-acceptance-fixture-runtime.t
---

Decision `0087` separates process mechanics from domain policy. Private
`FSM::Test::ProcessSupervisor` owns shell-free argv, same-volume repository cwd,
split aggregate-bounded capture, close-on-exec handoff evidence, monotonic time,
one process group, first-failure status, and verified TERM/KILL cleanup.
Commands, bounds, schemas, and platform guards belong to sealed adapters under
`t/lib/FSM/Test/`; the watcher recomputes their exclusive call ownership.

`FSM::Test::VerilatorRuntime` retains decision `0086`'s Darwin qualification and
version/compile/runtime contracts. `FSM::Test::TaskAcceptanceFixtureRuntime`
accepts only project-local task-acceptance fixture repositories. It allowlists
fixture Git argv, including only local identity configuration and relative add
paths; walls are ten seconds, Git/checker capture is 1,048,576/4,194,304 bytes,
and results use closed `fsmgen.test.task_acceptance_fixture_result.v1` records.
Callers cannot widen policy. Git is resolved/canonicalized once at load time;
later PATH replacement cannot change it.

The original checker used unbounded `IPC::Cmd` through `#!/usr/bin/env bash`
and stalled before main on Darwin. The adapter resolves caller-selected Bash
from absolute PATH entries, canonicalizes it, and invokes it directly. The
retained falsification proves macOS `/bin/bash` 3.2 cannot run the checker's
empty-array loop under `set -u`. Bash and Git are read-only host dependencies;
fixtures, scratch, captured bytes, and diagnostics stay on the repository volume.

No retry: timeout, overflow, nonzero exit, signal, exec failure, surviving
descendants, and cleanup failure remain failures. Original task-acceptance
fixtures and result assertions pass unchanged through the adapter.

The Verilator hostile watcher generates fixture shebangs with canonical running
Perl. A combined gate observed its former env-Perl success fixture complete exec
handoff but hit the sealed wall before output. A source assertion allows env
Perl only on the watcher entrypoint invoked through Perl by `prove`.

T1595's recovery run sampled its env-Bash fake `uname` at `_dyld_start`, before
the metric ran. `run_guard` has sequential open3 capture, unbounded waitpid,
and exit-only status projection. HIAL/VIAL leaf `.19.2.3.1.2.2.6` owns verified
termination, interrupted failure, and pending fixture-policy selection. This
does not diagnose the OS cause or change production RAM formula/thresholds.
