---
id: test-subprocess-policy-adapters
title: Test subprocesses share one mechanism behind sealed policy adapters
answers:
  - "how are FSMGen test subprocesses bounded?"
  - "why does t1545 not use IPC Cmd?"
  - "why does the task-acceptance fixture invoke Bash directly?"
  - "who may call the low-level test process supervisor?"
  - "why can T1595 stall before measuring host memory?"
  - "can a nested supervised child survive an outer timeout?"
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
  scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib
  t/1545-task-acceptance-doctrine.t
  t/1668-darwin-inline-verilator-test-runtime.t
  t/1669-task-acceptance-fixture-runtime.t
---

Decisions `0087`/`0101` keep one engine in `FSM::Support::ProcessSupervisor`
behind the test compatibility wrapper. It owns shell-free argv, same-volume
repository cwd, bounded split streams, exec handoff, monotonic time, one process
group, first-failure status and TERM/KILL cleanup. Sealed adapters own commands,
bounds, schemas and platform guards; T1669 watches exclusive ownership.

`VerilatorRuntime` retains decision `0086`'s Darwin qualification and version/
compile/runtime contracts. `TaskAcceptanceFixtureRuntime` admits only owned
fixture roots and fixed local Git argv. Its ten-second Git/checker stages cap
capture at 1,048,576/4,194,304 bytes and use the closed
`fsmgen.test.task_acceptance_fixture_result.v1` schema. Load-time canonical
Git/Bash identities ignore later PATH mutation; callers cannot widen policy.

The original env-Bash checker stalled before main on Darwin. Direct selected
Bash preserves capability: the retained `/bin/bash` 3.2 control fails its empty
array under `set -u`. Bash/Git are read-only host dependencies; project data
stays local. Timeout, overflow, nonzero, signal, exec, group-descendant and
cleanup failures stay failed without retry; original fixture assertions pass.

The Verilator watcher uses canonical Perl fixture shebangs after an env-Perl
fixture reached exec handoff but timed out before output. Only the entrypoint
invoked through Perl by `prove` may retain an env shebang.

T1595's env-Bash fake uname stalled at `_dyld_start` before measuring memory.
Its sequential open3 capture, unbounded wait and exit-only projection remain
owned by HIAL/VIAL `.19.2.3.1.2.2.6`. This does not diagnose the OS cause or
change production memory formulas/thresholds.

A nested probe found an inner group alive after outer timeout reported its
own group gone. Group cleanup does not compose into nested-subtree cleanup.
The exact escaped group was terminated and absence verified. HIAL/VIAL
`.19.2.3.1.2.2.5.5` owns the required ownership design, repair and hostile
watcher; neutral-verifier extraction remains provisional and blocked.
