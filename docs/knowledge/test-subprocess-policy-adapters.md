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
  - "how does inactive image membership reject enumeration errors?"
  - "what do inactive coordinator interruption cuts prove?"
  - "what do inactive semantic-census interruption cuts prove?"
  - "how do census close errors preserve the primary failure?"
  - "why must snapshot cut selectors identify unique occurrences?"
  - "which remaining acquisition close reports are qualified?"
  - "how is the complete inactive acquisition matrix joined?"
  - "why can an observer settled event leave a helper running?"
  - "what must settle before an observation hold is released?"
  - "how do archive records preserve all retained source identities?"
  - "can retained snapshots be archived after the workspace is retired?"
  - "how are repeated archive boundaries and handle lifetimes distinguished?"
  - "what survives ordinary fresh archive call interruptions?"
  - "what survives existing archive verification interruptions?"
  - "how do equal-content archive failures preserve original identities?"
  - "what survives equal-content existing archive interruptions?"
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
`exec_handoff_monotonic_ns` is EOF, not main-entry proof; absent EOF leaves timing unknown. Limits/controls: history.
`VerilatorRuntime` follows decision `0086`.
`TaskAcceptanceFixtureRuntime` seals owned fixture roots/fixed local Git argv.
Supervisor, checker, locality, startup/capture/STOP controls: history; absent witnesses stay unknown.
History: `af76fe3c794dc020e4de71789d24a13eafcbca76:docs/knowledge/test-subprocess-policy-adapters.md`.
PST parsing, serial-queue evidence, fixed CLI limits and controls: history.
Records, custody, acquisition and unique-occurrence correction: history.
A scoped settled event can leave a caller-owned helper running; release still needs every selected owner settled, including cancellation. Contract/model: history.
Archive records, retirement/reuse and earlier call cuts: history.
Unique archive calls/handles: history. Source-return and close observations are not throwing fault selectors.
Equal-content existing cuts preserve complete deduplicated archives and distinct original identities; preparation and cleanup are observed. Evidence: `docs/audits/native-proxy-observation-archive-equal-existing-calls-20260911/audit.py`. Partial-write, close and release gates remain open.
Caller-sealed test wrappers use tail goto to preserve caller.
Replay: `scripts/run_with_ram_guard.sh -- python3 -B -m unittest discover -s t/python -p 'test_fixture_policy_archive*.py'`.
RAM guard/T1595/T1811/T1669 controls and open causes: history.
Per-group cleanup cannot prove nested cleanup; actual counterexample: history.
HIAL/VIAL `.19.2.3.1.2.2.5.5` owns ownership design, repair and hostile controls;
neutral-verifier extraction stays provisional/blocked.
Coordinator selection and open gates: history. Archive replay prerequisites: `docs/audits/native-proxy-observation-archive-replay-20260911/issue.json`.
