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
  - "how are passive fixture identities and sources tracked?"
  - "why does fixture capture need repeated authentication?"
  - "why did T1669 admission miss its workspace?"
  - "how are fixture command-query exit races handled?"
  - "how are queued-only fixture policy tokens attributed?"
  - "how is fixture calibration preflight checked?"
  - "how does the fixed daemon capture caller work?"
  - "how does the finite daemon sequence preserve its budget and helper?"
  - "how are fixture policy publication receipts verified?"
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
date: 2026-09-09
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
  t/1669-task-acceptance-fixture-runtime.t
reverify: >-
  scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib
  t/1545-task-acceptance-doctrine.t
  t/1668-darwin-inline-verilator-test-runtime.t
  t/1669-task-acceptance-fixture-runtime.t t/1812-process-coordinator-endpoint.t
  t/1813-process-coordinator-connection.t t/1814-process-coordinator-service.t
---

Decisions `0087`/`0101`: `FSM::Support::ProcessSupervisor` offers nonblocking steps to synchronous callers: shell-free argv, same-volume cwd, bounded split capture, exec handoff, monotonic time, one group, first-failure status, TERM/KILL cleanup. Adapters seal commands/bounds/schemas/platform guards; T1669 checks exclusive ownership.
Child requires successful `setpgid` and actual owned group before exec. `.3.2.10.1` separates return/errno, exception and membership diagnostics with child PID; native session/false-success controls reject stale-error attribution. PID is not birth identity. Parent race closure cannot replace admission; nested cleanup stays open.
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
T1545: canonical JSON TAP diagnostics preserve failed checker results separately from output. Nonzero controls prove empty/split-stream recovery; older discarded cause unknown.
Launch observation retains commands/results, identity and bounded progress. Bash PID/native-output/held-child controls qualify it; missing progress stays unknown (task/book).
Env-Perl timed out after handoff; Verilator uses canonical Perl, except the `prove` entrypoint. Direct-Perl timeouts refute a shebang-only cure. HIAL/VIAL `.19.2.3.1.2.2.5.5.2.3.1.2.2.3` owns `_dyld_start`/fixture diagnosis. `.3.3–7` qualify fixed authenticated kernel capture and reject thread-state substitution; `.3.2` owns causal repair. `bash scripts/await_fixture_kernel_samples.sh` checks identity/expiry/STOP; tests stay normal-user. `.3.8.7` keeps one helper per sequence; standalone STOP needs fresh authentication.
T1669 uses `.artifacts/tmp/process-supervisor-tests/`. Every ps result needs native presence; only disappearance is skipped. Permission/query/live identity changes fail. Native exit and unchecked-ps controls qualify that race, not the historical changed field (`.3.2.11`; book/task).
History: `93e7072566e2dce7b70c10fa04ffc8765b35b1e9:docs/knowledge/test-subprocess-policy-adapters.md`. Combined original passes without capture; startup cause stays open (.3.2.15.3.3).
Command/header/joins verified. Pinned archive replay omits old root/CFHash; rederivation unavailable; unauthenticated. Diagnostics omit raw text/bodies. Receipts bind calibration/artifacts; consumption needs no private inputs. Daemon caller preflights, settles, publishes; preserves failures/ownership. The shared finite controller pins calibration, rechecks the full reserve after preflight, verifies each actual receipt/current iteration and stops at first failure/capture. Fixed CLI pending (.15.5.2.2). F_CHECK_LV shared cause unproved (.15.2); queues/provenance coexist (.15.4). Worker/delivery unknown. Live opt-in violations: .15.5.1.2.2–3.
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

Earlier passing T1668 capture `.3.7`: exact birth/source identities, AppleSystemPolicy offsets/image UUIDs, XProtect/provenance and cleanup limits remain at `ae992d5178a8bc68756402f51244bff752744bbd:docs/knowledge/test-subprocess-policy-adapters.md`. That passing policy wait cannot explain an older timeout; raw diagnostic artifacts remain an explicit durability gap.
Approved iTerm2 Developer Tools is on; Terminal/Tracing off. Unchanged band passes.
Exact `ju79K1mKs1/orphaning-runtime` still has XProtect results at `16:05:05.243719 +0200`, path `6bce9d1ba3a14e47`.
[Apple's process-tree paste inspection](https://support.apple.com/en-euro/guide/security/sece3b202c4b/web) is unproved here.
Fresh shell/Codex passes with exact-fixture XProtect scans; identities: `.3.2`. Fixture provenance, no quarantine; repair open.
