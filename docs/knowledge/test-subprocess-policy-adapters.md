---
id: test-subprocess-policy-adapters
title: Test subprocesses share one mechanism behind sealed policy adapters
answers:
  - "how are FSMGen test subprocesses bounded?"
  - "why does t1545 not use IPC Cmd?"
  - "why does the task-acceptance fixture invoke Bash directly?"
  - "who may call the low-level test process supervisor?"
date: 2026-08-26
status: current
tags: [tests, subprocess, supervision, task-acceptance, darwin, locality]
evidence: >-
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

Decision `0087` separates reusable process mechanics from domain policy.
Private `FSM::Test::ProcessSupervisor` owns shell-free argv, repository-
contained same-volume cwd, separate aggregate-bounded streams, close-on-exec
handoff evidence, monotonic timing, one owned process group, first-failure
statuses, and verified TERM/KILL cleanup. It does not choose commands, bounds,
schemas, or platform guards. Only sealed policy adapters in `t/lib/FSM/Test/`
may call it, and the focused watcher recomputes that ownership.

`FSM::Test::VerilatorRuntime` remains decision `0086`'s policy adapter with
unchanged Darwin qualification and version/compile/runtime contracts.
`FSM::Test::TaskAcceptanceFixtureRuntime` owns `t/1545`: it accepts only
project-local task-acceptance fixture repositories, allowlists the fixture Git
argument shapes (including only local identity configuration and repository-
relative add paths), applies fixed ten-second walls, caps aggregate Git/checker
capture at 1,048,576/4,194,304 bytes, and returns the closed
`fsmgen.test.task_acceptance_fixture_result.v1` record. Callers cannot widen
those choices.
The adapter resolves and canonicalizes the inherited `git` executable once at
load time, so later `PATH` replacement cannot change the admitted tool.

The original checker launch used unbounded `IPC::Cmd` through
`#!/usr/bin/env bash` and stopped at the qualified Darwin pre-main boundary.
The adapter likewise resolves the caller-selected `bash` from absolute `PATH` entries,
canonicalizes it, and invokes that exact executable directly. This removes the
failed `env` handoff without switching the checker to macOS `/bin/bash` 3.2,
which the retained falsification replay proves cannot execute the current
empty-array loop under `set -u`. Bash is an explicit read-only host/toolchain
dependency alongside Git; every project-owned fixture, scratch file, captured byte, and
diagnostic remains on the repository volume.

There is no retry. Timeout, output overflow, nonzero exit, signal, exec
failure, surviving descendants, or cleanup failure stays failed. The original
task-acceptance fixtures and result assertions remain unchanged and pass under
the adapter.

The Verilator hostile watcher also generates its programs with the canonical
already-running Perl interpreter in their shebangs. A combined gate proved why:
its former `#!/usr/bin/env perl` success fixture completed exec handoff but
reached the sealed wall before first output. A source assertion now permits an
env-Perl shebang only on the watcher entrypoint that `prove` invokes through
Perl, closing recurrence without retry.
