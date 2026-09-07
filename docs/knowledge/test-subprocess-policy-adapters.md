---
id: test-subprocess-policy-adapters
title: Test subprocesses share one mechanism behind sealed policy adapters
answers:
  - "how are FSMGen test subprocesses bounded?"
  - "why does t1545 not use IPC Cmd?"
  - "where does T1545 preserve empty-output checker failure diagnostics?"
  - "where does T1545 retain actual checker PID and startup observations?"
  - "can native thread state replace kernel sampling of fixture startup?"
  - "how do I start an authenticated fixture sampling session?"
  - "why did T1669 admission miss its workspace?"
  - "how are fixture command-query exit races handled?"
  - "what does the AppleSystemPolicy fixture startup capture establish?"
  - "what does exec_handoff_monotonic_ns prove about child startup?"
  - "why does the task-acceptance fixture invoke Bash directly?"
  - "who may call the low-level test process supervisor?"
  - "why can T1595 stall before measuring host memory?"
  - "can a nested supervised child survive an outer timeout?"
  - "how does the supervisor reject failed setpgid before exec?"
  - "can post-KILL leader reaping bypass the cleanup deadline?"
  - "which ownership model is selected for nested supervision?"
  - "how does the private coordinator preserve execution bytes?"
date: 2026-09-08
status: current
tags: [tests, subprocess, supervision, task-acceptance, darwin, locality]
evidence: >-
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md;
  t/1595-agent-runtime-ram-guard-macos-metric.t; t/1811-ram-guard-fixture-runtime.t; t/lib/FSM/Test/RamGuardFixtureRuntime.pm;
  docs/decisions/0087-test-subprocesses-use-shared-mechanism-and-sealed-policy-adapters.md;
  docs/tasks/DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.md;
  docs/book/src/16dc-vial-portable-verilator-runtime-measurement.md;
  t/lib/FSM/Test/ProcessSupervisor.pm; t/lib/FSM/Test/TaskAcceptanceFixtureRuntime.pm; t/lib/FSM/Test/VerilatorRuntime.pm;
  t/1545-task-acceptance-doctrine.t;
  t/1668-darwin-inline-verilator-test-runtime.t;
  scripts/fixture_kernel_sampler.py; t/python/test_fixture_kernel_sampler.py;
  t/1669-task-acceptance-fixture-runtime.t
reverify: >-
  scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib
  t/1545-task-acceptance-doctrine.t
  t/1668-darwin-inline-verilator-test-runtime.t
  t/1669-task-acceptance-fixture-runtime.t t/1812-process-coordinator-endpoint.t
  t/1813-process-coordinator-connection.t t/1814-process-coordinator-service.t
---

Decisions `0087`/`0101` keep one engine in `FSM::Support::ProcessSupervisor`
with nonblocking advancement behind synchronous callers: shell-free argv, same-volume
repository cwd, bounded split streams, exec handoff, monotonic time, one process
group, first-failure status and TERM/KILL cleanup. Sealed adapters own commands,
bounds, schemas and platform guards; T1669 watches exclusive ownership.
The child checks POSIX `setpgid` return and actual group before exec.
Nonthrowing failure and false success reject with `exec_error` and no command
execution; T1669 injects both plus an exception. The parent's race-closing
attempt cannot replace child admission. Nested cleanup remains open below.
`exec_handoff_monotonic_ns` records observed control-pipe EOF, not entry into
main: abrupt pre-exec child death can also close the pipe. Capture ending
without EOF leaves that timestamp and dependent durations unknown even after
cleanup. T1669 holds a real child before exec through timeout and separately
exits it before exec; successful output remains a distinct positive control.
Post-KILL reaping uses nonblocking polling inside the existing cleanup grace;
an unreapable leader or surviving group remains explicitly incomplete. T1669's
isolated mock oracle rejects blocking waits without creating an unkillable child.
`VerilatorRuntime` retains decision `0086`'s Darwin qualification and version/
compile/runtime contracts. `TaskAcceptanceFixtureRuntime` admits only owned
fixture roots and fixed local Git argv. Its ten-second Git/checker stages cap
capture at 1,048,576/4,194,304 bytes and use the closed
`fsmgen.test.task_acceptance_fixture_result.v1` schema. Load-time canonical
Git/Bash identities ignore later PATH mutation; callers cannot widen policy.
The original env-Bash checker stalled before main on Darwin. Direct selected
Bash preserves capability: the retained `/bin/bash` 3.2 control fails its empty
array under `set -u`. Bash/Git are read-only host dependencies; project data
stays local. Timeout/overflow/nonzero/signal/exec/descendant/cleanup failures stay failed
without retry; original fixture assertions pass.
T1545 retains failed checker results as canonical JSON TAP diagnostics separate
from checker output. Real nonzero controls verify empty/split streams and full
recovery; the older discarded empty-output result has unknown cause.
Launch observation retains child identity and bounded progress with unchanged
commands/results. Bash PID, native output and held-child controls qualify it;
missing progress stays unknown. Task/book own qualification and boundaries.
After an env-Perl fixture reached exec handoff yet timed out before output,
Verilator fixtures use canonical Perl shebangs. Only `prove`'s Perl-invoked
entrypoint may retain an env shebang.
Direct-Perl timeouts show the shebang repair is insufficient:
HIAL/VIAL `.19.2.3.1.2.2.5.5.2.3.1.2.2.3` owns the live `_dyld_start` sample,
Rust proxy/Verilator fixture diagnosis and repair. OS cause stays unknown;
child `.3.3` records targeted kernel sampling and its administrator-authentication
prerequisite, with capture owned by `.3.4` before causal repair selection.
Child `.3.5` rejects a thread-state-only substitute: its independently stopped
pipe reader still reports a waiting thread. This does not identify the OS cause.
`.3.6`: `bash scripts/await_fixture_kernel_samples.sh` supplies local authentication,
normal-user repeated fixed captures, identity checks, expiry and STOP/Ctrl+C.
`.3.7` closes native capture/shutdown verification; `.3.2` owns causal repair.
T1669 admission uses its real allocator's `.artifacts/tmp/process-supervisor-tests/` root.
An empty observation fails coverage; `.3.8.5`/book own the contract.
A `ps` no-match skips only native absence; `.3.8.6` retains other errors.
T1595's pre-main cause stays open; `.19.2.3.1.2.2.6.2` fixes capture.
`RamGuardFixtureRuntime` seals tools/argv, paths, bounds and full results.
T1811/T1669 prove signal/stream failures and group cleanup; T1595 keeps metrics.
No retry or production threshold change.

An outer timeout proved its group gone but left an inner group alive. That group
was terminated; absence verified. Per-group cleanup cannot prove nested cleanup.
HIAL/VIAL `.19.2.3.1.2.2.5.5` owns ownership design, repair and hostile controls;
neutral-verifier extraction stays provisional/blocked.
Selected: one launch coordinator, private clients, reserved identities and bounded wire/context/lifecycle protocol.
T1669 proves reservation feasibility. Extraction, Wire and inactive endpoint/service transport are implemented;
coordination, routing and hostile qualification (including startup diagnosis) remain open.

Native capture `.3.7` on 2026-09-07 binds normal-user Perl fixture PID `22778`
(`1788787261.244839`) to T1668 parent `21913` (`1788787240.646851`). Source:
`.artifacts/tmp/tests/eyRjEqbQuI/orphaning-runtime`, SHA-256
`51805be68accf0933248e791444815bf1f4a3d51faca75c739c03dc92ee10dd5`.
Report SHA-256: `e1306078fdb46858ce867f1411d83f52dc3d366e5971ff0384404d89da504d5b`;
sample interval: `15:21:02.594–15:21:03.596 +0200`. AppleSystemPolicy offsets:
`33268 → 32024 → 27236 → 13740`, image UUID `8474AAC8-5327-3045-A969-9B20DBF588BD`.
Kernel UUID `3F7964F9-C5A6-39D4-942D-02750C0980E0` matches the installed arm64e kernel.
Independent info/debug `syspolicyd` at `15:21:07 +0200` names the
exact fixture in `GK Xprotect results` and `evaluation result: 12666, script, allowed, cache`;
process-provenance also names PID `22778`. Default and original-failure queries are empty.
This passing invocation's policy wait cannot explain the older timeout.
The task owns cleanup, failed-selector/symbolization limits; OS/toolchain reads are dependencies. Root sampler birth identity was not retained; nested cleanup is unproved.
Helper STOP invalidates authentication; independent observed-process and exact-command
censuses are empty. Identities/offsets/results are durable here and in Git;
Raw logs and scratch producers remain ignored: an explicit durability gap.
See `.artifacts/logs/fixture-kernel-recurrence-20260907/` and the task's capture session.
Approved iTerm2 Developer Tools is on; Terminal/Tracing off. The unchanged band passes.
Exact `ju79K1mKs1/orphaning-runtime` still has XProtect results at `16:05:05.243719 +0200`, path `6bce9d1ba3a14e47`.
[Apple's process-tree paste inspection](https://support.apple.com/en-euro/guide/security/sece3b202c4b/web) is unproved here.
Fresh shell/Codex passes with exact-fixture XProtect scanning; `.3.2` retains identities. Fixture has provenance, no quarantine; repair open.
