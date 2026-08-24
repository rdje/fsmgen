---
id: vial-verilator-shared-lifecycle
title: One caller-sealed lifecycle owns public and scale Verilator execution
answers:
  - "how will the Runner and scale measurement share Verilator stages?"
  - "how does the shared Verilator lifecycle preserve state and cleanup authority?"
  - "why can portable Verilator time out before generated main on macOS?"
date: 2026-08-24
status: current
tags: [vial, verilator, lifecycle, runner, scalability]
evidence: >-
  docs/decisions/0083-portable-systemverilog-runtime-scale-uses-authored-cycle-sampling-and-one-shared-staged-lifecycle.md;
  perl/FSM/VIAL/Backend/VerilatorLifecycle.pm;
  perl/FSM/VIAL/Backend/Runner.pm;
  t/1640-vial-runner-capture-limits.t;
  t/1558-vial-verilator-run-integration.t;
  t/1664-vial-verilator-shared-lifecycle.t;
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md;
  docs/book/src/16dc-vial-portable-verilator-runtime-measurement.md
reverify: >-
  rg -n 'admitted|prepared|tool_verified|compiled|ran|trace_validated|result_produced|assembled|cleaned|content-addressed|workspace-normalized'
  perl/FSM/VIAL/Backend/VerilatorLifecycle.pm
  docs/book/src/16dc-vial-portable-verilator-runtime-measurement.md &&
  prove -Iperl t/1640-vial-runner-capture-limits.t
  t/1664-vial-verilator-shared-lifecycle.t
---

Decision `0083` selects one private caller-sealed
`FSM::VIAL::Backend::VerilatorLifecycle` for both public Runner execution and
process-isolated scale stages. Active `.17.3.5.3` implements its forward-only
admitted/prepared/tool-verified/compiled/ran/trace-validated/result-produced/
assembled/cleaned chain. Each consumer reconstructs ExecutionIR and emission
authority, validates the complete canonical state census, predecessors, exact
object-kind inventory, object bytes/digests/modes, prepared input copies, and
the compiled executable before advancing. Public and measurement storage roots
remain caller-sealed; measurement command paths are rebased and re-digested
while separate workspace-normalized identities remain equal to the public
route. Runner is only the existing public result adapter over that lifecycle.
Its total-function boundary contains both lifecycle exceptions and malformed
private projections as sanitized host errors without publishing artifacts or
trusting partial cleanup claims.
Reference stays correctness-only; nominal record limit/excess stay byte-
preflight dominated; other backend selection remains separate.

The public Runner still exposes the external stages as one atomic transaction,
but the shared lifecycle is their sole implementation owner. It uses close-on-
exec error control, control-before-output observation, an inclusive aggregate
capture budget, a deadline that remains active after output-pipe closure, and
whole-process-group TERM/KILL verification. Source-text patching, padded or
truncated output, duplicated execution semantics, hidden public widening, and
borrowed runtime, support, performance, or capacity claims remain rejected.

Repeated guarded full integration attempts timed out different baseline/direct
executions at Runner's fixed 30-second run wall while byte-identical executions
passed in other attempts under concurrent compiler load. The lifecycle
evidence separates containment/spawn, successful `exec`, first output, and
exit. Three implementation-time failures reached `exec` in 3.7-4.1 ms, then
produced zero bytes before the unchanged deadline. A read-only 3-second sample
of one 1,847,672-byte ARM64 generated executable observed all 2,389 main-thread
samples at `_dyld_start`, with a 96-KiB footprint and no binary-image map. That
proves the sampled stall preceded generated FSMGEN main/output, but the
concurrent unrelated Rust compilation plus 28.6%-CPU `syspolicyd` activity and
one separate 30.179-second policy-network timeout are correlation only.
Proposed `.17.3.5.3.1` owns quiet-host and platform-control falsification; no
retry, signing/security change, timeout widening, or passed-result fabrication
is selected.

The guarded exact lifecycle test nevertheless traverses every sealed state
with qualified Verilator, assembles 12 public artifacts, and cleans exactly;
the separate guarded AHB runtime-parity watcher passes. The broader public
integration watcher passes six of seven top-level subtests, but its repeated
byte-identical direct-drive executable alone reaches the same unchanged wall
after the first execution passes. That failure remains explicit evidence for
`.17.3.5.3.1`, not an implementation pass or a reason to change the contract.

Related: [[vial-architecture-scale-proof]],
[[hial-vial-verification-fixture-architecture]].
