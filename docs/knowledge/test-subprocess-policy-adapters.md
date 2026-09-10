---
id: test-subprocess-policy-adapters
title: Test subprocesses share one mechanism behind sealed policy adapters
answers:
  - "how are FSMGen test subprocesses bounded?"
  - "how are native Rust proxy fixtures built and qualified?"
  - "why did integrated proxy qualification fail?"
  - "why does t1545 not use IPC Cmd?"
  - "where does T1545 preserve empty-output checker failure diagnostics?"
  - "where does T1545 retain actual checker PID and startup observations?"
  - "can native thread state replace kernel sampling of fixture startup?"
  - "how do I start an authenticated fixture sampling session?"
  - "how are passive fixture identities and sources tracked?"
  - "why does fixture capture need repeated authentication?"
  - "why did T1669 admission miss its workspace?"
  - "how are fixture command-query exit races handled?"
  - "how are queued-only fixture policy tokens attributed?"
  - "how is fixture calibration preflight checked?"
  - "how does the fixed daemon capture caller work?"
  - "how can I observe daemon context without kernel authentication?"
  - "how does the finite daemon sequence preserve its budget and helper?"
  - "how are fixture policy publication receipts verified?"
  - "why can shortened PST tokens stop daemon publication?"
  - "why does a saturated daemon capture need bounded archive pages?"
  - "how are calibrated archive pages built without losing metadata?"
  - "how does policy publication handle replaced directories?"
  - "how will policy diagnostics avoid private paths?"
  - "which fixture bands wrongly ran live collectors?"
  - "which call delayed the native library load?"
  - "why must fixture clock domains stay separate?"
  - "where does T1669 retain failed legacy main entry diagnostics?"
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
date: 2026-09-10
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
  scripts/observe_fixture_startup.py; t/python/test_fixture_census.py;
  scripts/analyze_fixture_policy.py; t/python/test_fixture_policy_analysis.py;
  scripts/fixture_policy_associations.py; t/python/test_fixture_policy_associations.py;
  scripts/run_fixture_startup_policy_observation.py; scripts/run_fixture_startup_daemon_observation.py; t/python/test_fixture_startup_policy_observation.py;
  t/1669-task-acceptance-fixture-runtime.t; t/python/test_fixture_runtime_sources.py;
  t/lib/FSM/Test/RustProxyFixture.pm; t/1815-rust-proxy-fixture.t; t/1816-rust-proxy-integration.t; t/1817-test-supervision-architecture.t
reverify: >-
  scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib
  t/1545-task-acceptance-doctrine.t
  t/1668-darwin-inline-verilator-test-runtime.t
  t/1669-task-acceptance-fixture-runtime.t t/1812-process-coordinator-endpoint.t
  t/1813-process-coordinator-connection.t t/1814-process-coordinator-service.t
  t/1815-rust-proxy-fixture.t t/1816-rust-proxy-integration.t t/1817-test-supervision-architecture.t
---

Decisions `0087`/`0101`: `FSM::Support::ProcessSupervisor` gives synchronous callers nonblocking steps, shell-free argv, same-volume cwd, bounded split capture, monotonic measurements and one group with TERM/KILL cleanup. Adapters seal policy; T1669 checks ownership.
Child requires successful `setpgid` and owned group before exec. `.3.2.10.1` separates return/errno, exception and membership with child PID; native session/false-success controls reject stale-error attribution. PID is not birth identity. Parent race closure cannot replace admission; nested cleanup stays open.
`exec_handoff_monotonic_ns` means observed control-pipe EOF, not main entry:
pre-exec death can close it. Without observed EOF, that timestamp and dependent
durations stay unknown even after cleanup. T1669 checks held-child timeout, separate pre-exec exit and successful output.
Post-KILL reaping polls nonblocking within cleanup grace. Unreaped leaders/surviving groups stay incomplete; T1669's isolated mock rejects blocking waits without unkillable children.
`VerilatorRuntime` follows decision `0086`.
`TaskAcceptanceFixtureRuntime` seals owned fixture roots/fixed local Git argv.
Git/checker: ten-second wall, 1,048,576/4,194,304-byte capture, closed `fsmgen.test.task_acceptance_fixture_result.v1`. Load-time Git/Bash ignore later PATH; callers cannot widen policy.
Darwin env-Bash stalled before main. Direct Bash retains capability; `/bin/bash` 3.2 fails the empty array (`set -u`). Bash/Git are read-only host dependencies; project data
stays local. Timeout/overflow/nonzero/signal/exec/descendant/cleanup failures stay failed
without retry; original fixture assertions pass.
T1545 controls: historical card; absent witnesses stay unknown.
Env-Perl and direct Perl both timed out after handoff, refuting a shebang-only cure. HIAL/VIAL `.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2` owns startup cause; `.3.3–7` own authenticated kernel capture. Sampling/authentication/STOP limits remain in task/book and the exact historical card below.
T1669 uses `.artifacts/tmp/process-supervisor-tests/`. Every ps result needs native presence; only disappearance is skipped. Permission/query/live identity changes fail. Native exit and unchecked-ps controls qualify that race, not the historical changed field (`.3.2.11`; book/task).
History: `0f71d2c44e26bc5000302bd347d9203f13fb39ff:docs/knowledge/test-subprocess-policy-adapters.md`.
PST parsing normalizes 1–16 lowercase hex digits; malformed fields and contradictions reject.
.15.7.3: serial queue contention is supported; client/frame joins and startup repair stay open. Reduced-load and authored-native passes do not close them; OS copies hit launch constraints. .8 seals portable proxy preparation. .9 admits exact native ancestry and pinned C inputs with byte custody; .10 integrates owned mode retirement; .11 retains startup/registry failures; .11.3.1 fixes registration; .11.3.3 records preparation before runtime; .11.3.4.1 adds fixed passive daemon observation without kernel authentication. Loaded bytes remain unproved.
Fixed CLI .15.7.2.4 uses archive index/digest output and compact journal anchors; calibration/reserve/actual-file checks and first-failure/capture stop persist. Outcomes stay distinct; failures/ownership persist. F_CHECK_LV cause unproved (.15.2); queue/provenance coexist (.15.4); worker/delivery unknown. Live opt-in violations: .15.5.1.2.2–3.
Source controls: .11.3.4.1.2. Observed native joins pass (.4.3), but native scans persist (.4.4). Cause stays open; .12.2.2 refutes hard-link path stability: held A reports B after B access. No reuse run; .12.2.3 owns disposition.
Archive reverify: `scripts/run_with_ram_guard.sh -- python3 -B -m unittest discover -s t/python -p 'test_fixture_policy_archive*.py'`.
T1595 pre-main cause open; `.19.2.3.1.2.2.6.2` fixes capture.
`RamGuardFixtureRuntime` seals tools/argv, paths, bounds and full results.
T1811/T1669 prove signal/stream failures and group cleanup; T1595 keeps metrics.
Outer timeout proved its group gone but left an inner group alive; terminated and absence verified. Per-group cleanup cannot prove nested cleanup.
HIAL/VIAL `.19.2.3.1.2.2.5.5` owns ownership design, repair and hostile controls;
neutral-verifier extraction stays provisional/blocked.
Selected: one coordinator, private clients, reserved identities, bounded wire/context/lifecycle protocol.
T1669 proves reservation feasibility. Extraction, Wire, inactive endpoint/service transport are implemented;
coordination, routing and hostile qualification (including startup diagnosis) remain open.
