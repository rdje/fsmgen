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
  - "why does fixture capture need repeated authentication?"
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

Decisions `0087`/`0101`: `FSM::Support::ProcessSupervisor` has nonblocking steps behind synchronous callers: shell-free argv, same-volume
repository cwd, bounded split streams, exec handoff, monotonic time, one process
group, first-failure status and TERM/KILL cleanup. Sealed adapters own commands,
bounds, schemas and platform guards; T1669 watches exclusive ownership.
Child checks POSIX `setpgid` return and actual group before exec. False/nonthrowing failures yield `exec_error` without execution; T1669 injects both plus exception. Parent race closure cannot replace admission; nested cleanup open.
`exec_handoff_monotonic_ns` means observed control-pipe EOF, not main entry:
pre-exec death can close it. Without observed EOF, that timestamp and dependent
durations stay unknown even after cleanup. T1669 holds a real pre-exec child
through timeout and separately exits it; successful output is the positive control.
Post-KILL reaping polls nonblocking within cleanup grace. Unreaped leaders/surviving groups stay incomplete; T1669's isolated mock rejects blocking waits without unkillable children.
`VerilatorRuntime` retains `0086`'s Darwin qualification and version/compile/runtime contracts.
`TaskAcceptanceFixtureRuntime` seals owned fixture roots/fixed local Git argv.
Git/checker: ten-second wall, 1,048,576/4,194,304-byte capture, closed `fsmgen.test.task_acceptance_fixture_result.v1`. Load-time Git/Bash ignore later PATH; callers cannot widen policy.
Darwin env-Bash stalled before main. Direct Bash preserves capability: the retained `/bin/bash` 3.2 control fails its empty
array under `set -u`. Bash/Git are read-only host dependencies; project data
stays local. Timeout/overflow/nonzero/signal/exec/descendant/cleanup failures stay failed
without retry; original fixture assertions pass.
T1545: canonical JSON TAP diagnostics preserve failed checker results separately from output. Nonzero controls prove empty/split-stream recovery; older discarded cause unknown.
Launch observation retains commands/results, identity and bounded progress. Bash PID/native-output/held-child controls qualify it; missing progress stays unknown (task/book).
Env-Perl reached handoff then timed out without output; Verilator fixtures now use canonical Perl shebangs. Only the `prove` Perl-invoked entrypoint may retain env.
Direct-Perl timeouts refute a shebang-only cure:
HIAL/VIAL `.19.2.3.1.2.2.5.5.2.3.1.2.2.3` owns the live `_dyld_start` sample,
Rust proxy/Verilator fixture diagnosis and repair;
child `.3.3` owns kernel-sampling selection and required administrator authentication;
`.3.4` owns capture before causal repair.
`.3.5` rejects thread-state substitution: an independently stopped pipe reader
still reports waiting.
`.3.6`: `bash scripts/await_fixture_kernel_samples.sh` authenticates fixed kernel
captures; tests stay normal-user. Identity, expiry and STOP/Ctrl+C checks remain.
`.3.8.7` keeps one helper per sequence; single-run STOP needs fresh authentication.
`.3.7` closes native capture/shutdown verification; `.3.2` owns causal repair.
T1669 allocates under `.artifacts/tmp/process-supervisor-tests/`; empty coverage fails (`.3.8.5`/book). A `ps` no-match skips only native absence; `.3.8.6` retains other errors.
Selection/live-policy and full-Rust-JSON/distinct-path repairs: `.3.8.9–.17` (task). `.3.8.8/.14` sample passing Rust; `.3.8.11/.14` fail Rust without its stack; `.3.8.16` passes without capture. `.3.8.18` captures the failed decoy in AppleSystemPolicy: exact native/source ancestry, full timeout JSON, later distinct-path policy record and verified observed cleanup. Same frames occur in passing samples; full-deadline wait, daemon cause, Rust main entry and failed legacy stack remain unknown. Prior token-only queue/wakeup records fail the default path filter; `.3.2.2` qualifies execution_context, strict scope/command reload and the native old-filter counterexample.
T1595's pre-main cause stays open; `.19.2.3.1.2.2.6.2` fixes capture.
`RamGuardFixtureRuntime` seals tools/argv, paths, bounds and full results.
T1811/T1669 prove signal/stream failures and group cleanup; T1595 keeps metrics.
No retry/threshold change.
Outer timeout proved its group gone but left an inner group alive; terminated and absence verified. Per-group cleanup cannot prove nested cleanup.
HIAL/VIAL `.19.2.3.1.2.2.5.5` owns ownership design, repair and hostile controls;
neutral-verifier extraction stays provisional/blocked.
Selected: one coordinator, private clients, reserved identities, bounded wire/context/lifecycle protocol.
T1669 proves reservation feasibility. Extraction, Wire, inactive endpoint/service transport are implemented;
coordination, routing and hostile qualification (including startup diagnosis) remain open.

Capture `.3.7`, 2026-09-07: normal-user Perl PID `22778`
(`1788787261.244839`) under T1668 `21913` (`1788787240.646851`). Source:
`.artifacts/tmp/tests/eyRjEqbQuI/orphaning-runtime`, SHA-256
`51805be68accf0933248e791444815bf1f4a3d51faca75c739c03dc92ee10dd5`.
Report SHA-256: `e1306078fdb46858ce867f1411d83f52dc3d366e5971ff0384404d89da504d5b`;
sample interval: `15:21:02.594–15:21:03.596 +0200`. AppleSystemPolicy offsets:
`33268 → 32024 → 27236 → 13740`, image UUID `8474AAC8-5327-3045-A969-9B20DBF588BD`.
Kernel UUID `3F7964F9-C5A6-39D4-942D-02750C0980E0` matches the installed arm64e kernel.
Independent info/debug `syspolicyd` at `15:21:07 +0200` names the
exact fixture in `GK Xprotect results` and `evaluation result: 12666, script, allowed, cache`;
process-provenance also names PID `22778`. Default/original-failure queries are empty; this passing wait cannot explain the older timeout.
Task: cleanup/selector/symbol limits. OS/toolchain: read dependencies. Root sampler birth is unretained; nested cleanup unproved.
Helper STOP invalidates authentication; independent observed-process and exact-command censuses are empty. Git preserves identities/offsets/results; ignored raw logs/scratch producers are a durability gap.
See `.artifacts/logs/fixture-kernel-recurrence-20260907/` and the capture session.
Approved iTerm2 Developer Tools is on; Terminal/Tracing off. Unchanged band passes.
Exact `ju79K1mKs1/orphaning-runtime` still has XProtect results at `16:05:05.243719 +0200`, path `6bce9d1ba3a14e47`.
[Apple's process-tree paste inspection](https://support.apple.com/en-euro/guide/security/sece3b202c4b/web) is unproved here.
Fresh shell/Codex passes with exact-fixture XProtect scans; identities: `.3.2`. Fixture provenance, no quarantine; repair open.
