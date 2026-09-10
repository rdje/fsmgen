---
id: test-subprocess-policy-adapters
title: Test subprocesses share one mechanism behind sealed policy adapters
answers:
  - "how are FSMGen test subprocesses bounded?"
  - "how are native Rust proxy fixtures built and qualified?"
  - "why must native-birth field sets use explicit membership?"
  - "what does the inactive runtime-reference codec validate?"
  - "how does the inactive reference census retain stale owners?"
  - "how does inactive acquisition order global and private references?"
  - "how must tests wrap a caller-sealed function?"
  - "which cleanup receipts must settle before proxy retirement?"
  - "how does inactive private workspace retirement retain image pins?"
  - "when can inactive maintenance remove a canonical image?"
  - "what does the inactive observation-reference codec validate?"
  - "how are runtime and observation references counted together?"
  - "how does fresh observation acquisition retain source snapshots?"
  - "how does stable observation reuse preserve the original hold?"
  - "why must fixture clones preserve byte flags and JSON numeric types?"
  - "why do inactive source and writer handoffs close explicitly?"
  - "what do inactive observation snapshot interruption cuts prove?"
  - "what survives inactive observation publication failures?"
  - "how does inactive namespace enumeration reject read errors?"
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
date: 2026-09-11
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

Decisions `0087`/`0101` select `FSM::Support::ProcessSupervisor`; adapters seal bounded local argv/capture/group cleanup. T1669 checks ownership.
Child requires its owned group before exec; birth/cleanup controls: history.
`exec_handoff_monotonic_ns` observes pipe EOF, not main entry; pre-exec death can close it. Missing EOF leaves dependent timing unknown. Controls: history.
Post-KILL: poll within grace; unreaped leaders/live groups stay incomplete. T1669 rejects blocking waits.
`VerilatorRuntime` follows decision `0086`.
`TaskAcceptanceFixtureRuntime` seals owned fixture roots/fixed local Git argv.
Git/checker bounds, closed result schema and fixed load-time tools: history.
Darwin env-Bash pre-main stalls, direct Bash capability, locality and no-retry controls: history.
T1545 controls: historical card; absent witnesses stay unknown.
Env/direct Perl timeouts refute a shebang-only cure. Startup cause, authenticated capture and STOP limits: task/book/history.
T1669 uses process-supervisor-tests roots; ps skips only verified disappearance. Other errors fail; the historical changed field stays open (.3.2.11).
History: `295d186656a5d517894c1bdbd550b0633d2b2fc4:docs/knowledge/test-subprocess-policy-adapters.md`.
PST parsing normalizes 1–16 lowercase hex digits; malformed fields and contradictions reject.
Serial queue contention is supported; causal/native limits and controls: history.
Fixed CLI contracts/limits: history.
Combined census, fresh/reuse custody, FixtureClone types/octet flags, handoff/snapshot/publication controls and conservative holds: history. Release/capture/coordinator/native closure stays open.
Inactive namespace reads reject errors instead of returning partial names; capacity/read failures close explicitly and preserve the first error. Actual retained-directory controls: `docs/audits/native-proxy-namespace-reader-20260911/audit.py`. Synchronous injected faults do not establish an ordinary leak or full-acquisition bypass.
Caller-sealed test wrappers use tail goto to preserve caller.
Replay: `scripts/run_with_ram_guard.sh -- python3 -B -m unittest discover -s t/python -p 'test_fixture_policy_archive*.py'`.
T1595 pre-main cause open; `.19.2.3.1.2.2.6.2` fixes capture.
`RamGuardFixtureRuntime` seals tools/argv, paths, bounds and full results.
T1811/T1669 prove signal/stream failures and group cleanup; T1595 keeps metrics.
Outer timeout proved its group gone but left an inner group alive; terminated and absence verified. Per-group cleanup cannot prove nested cleanup.
HIAL/VIAL `.19.2.3.1.2.2.5.5` owns ownership design, repair and hostile controls;
neutral-verifier extraction stays provisional/blocked.
Selected: one coordinator, private clients, reserved identities, bounded wire/context/lifecycle.
T1669 proves reservation feasibility. Extraction, Wire, inactive endpoint/service transport are implemented;
coordination, routing and hostile qualification (including startup diagnosis) remain open.
