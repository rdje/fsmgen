---
id: test-subprocess-policy-adapters
title: Test subprocesses share one mechanism behind sealed policy adapters
answers:
  - "how are FSMGen test subprocesses bounded?"
  - "how are native Rust proxy fixtures built and qualified?"
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
  scripts/run_fixture_startup_policy_observation.py; t/python/test_fixture_startup_policy_observation.py;
  t/1669-task-acceptance-fixture-runtime.t;
  t/lib/FSM/Test/RustProxyFixture.pm; t/1815-rust-proxy-fixture.t
reverify: >-
  scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib
  t/1545-task-acceptance-doctrine.t
  t/1668-darwin-inline-verilator-test-runtime.t
  t/1669-task-acceptance-fixture-runtime.t t/1812-process-coordinator-endpoint.t
  t/1813-process-coordinator-connection.t t/1814-process-coordinator-service.t
  t/1815-rust-proxy-fixture.t
---

Decisions `0087`/`0101`: `FSM::Support::ProcessSupervisor` offers nonblocking steps to synchronous callers: shell-free argv, same-volume cwd, bounded split capture, exec handoff, monotonic time, one group, first-failure status, TERM/KILL cleanup. Adapters seal commands/bounds/schemas/platform guards; T1669 checks exclusive ownership.
Child requires successful `setpgid` and owned group before exec. `.3.2.10.1` separates return/errno, exception and membership with child PID; native session/false-success controls reject stale-error attribution. PID is not birth identity. Parent race closure cannot replace admission; nested cleanup stays open.
`exec_handoff_monotonic_ns` means observed control-pipe EOF, not main entry:
pre-exec death can close it. Without observed EOF, that timestamp and dependent
durations stay unknown even after cleanup. T1669 checks held-child timeout, separate pre-exec exit and successful output.
Post-KILL reaping polls nonblocking within cleanup grace. Unreaped leaders/surviving groups stay incomplete; T1669's isolated mock rejects blocking waits without unkillable children.
`VerilatorRuntime` retains `0086`'s Darwin qualification and version/compile/runtime contracts.
`TaskAcceptanceFixtureRuntime` seals owned fixture roots/fixed local Git argv.
Git/checker: ten-second wall, 1,048,576/4,194,304-byte capture, closed `fsmgen.test.task_acceptance_fixture_result.v1`. Load-time Git/Bash ignore later PATH; callers cannot widen policy.
Darwin env-Bash stalled before main. Direct Bash preserves capability: the retained `/bin/bash` 3.2 control fails its empty
array under `set -u`. Bash/Git are read-only host dependencies; project data
stays local. Timeout/overflow/nonzero/signal/exec/descendant/cleanup failures stay failed
without retry; original fixture assertions pass.
T1545 keeps failed-checker JSON separate from output; nonzero empty/split-stream controls pass. Older lost cause stays unknown.
Launch observation retains commands/results, identity and bounded progress. Bash PID/native-output/held-child controls qualify it; missing progress stays unknown (task/book).
Env-Perl and direct Perl both timed out after handoff, refuting a shebang-only cure. HIAL/VIAL `.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2` owns startup cause; `.3.3–7` own authenticated kernel capture. Sampling/authentication/STOP limits remain in task/book and the exact historical card below.
T1669 uses `.artifacts/tmp/process-supervisor-tests/`. Every ps result needs native presence; only disappearance is skipped. Permission/query/live identity changes fail. Native exit and unchecked-ps controls qualify that race, not the historical changed field (`.3.2.11`; book/task).
Prior evidence and earlier routes: `bb799b271876fe1ca60059b90579c66eea3fbd50:docs/knowledge/test-subprocess-policy-adapters.md`; .3.2.15.3.3 passes without capture; cause open.
PST parsing normalizes 1–16 lowercase hex digits; malformed fields and contradictions reject.
.15.7.3.2 verifies serial scan dispatch; preceding work spans the failed proxy queue wait. Client/frame joins remain open. .4 passes unchanged; .6 rejects OS copies (launch constraint); .7 authored bodies pass on this Mac, no repair proof. .8 adds the bounded builder, portable Perl choice and descriptor sealing; .9–11 own capture/integration. Archive pins/order/empty-stream rejection: task/book (.15.7.2–3).
V1 association replay needs pinned manifest/archives, no old root/CFHash; native rederivation unavailable, unauthenticated. Reports omit raw text/bodies; receipts bind calibration/artifacts without private reads. Fixed CLI .15.7.2.4 uses archive index/digest output and compact journal anchors; calibration/reserve/actual-file checks and first-failure/capture stop persist. Outcomes stay distinct; failures/ownership persist. F_CHECK_LV cause unproved (.15.2); queue/provenance coexist (.15.4); worker/delivery unknown. Live opt-in violations: .15.5.1.2.2–3.
Shared publish_bytes checks descriptor-anchored inode/bytes; existing files/primary failures persist. Later same-user mutation is unprotected (.15.7.2.3.1). Archive publication rejects fixed existing destinations and consumes pages before/after writing index last (.3.2).
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
