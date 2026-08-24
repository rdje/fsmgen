---
id: vial-verilator-shared-lifecycle
title: One caller-sealed lifecycle owns public and scale Verilator execution
answers:
  - "how will the Runner and scale measurement share Verilator stages?"
  - "how does the shared Verilator lifecycle preserve state and cleanup authority?"
  - "why can portable Verilator time out before generated main on macOS?"
  - "what did the macOS pre-main qualification conclude?"
  - "what portable Verilator measurement work is active after lifecycle qualification?"
date: 2026-08-24
status: current
tags: [vial, verilator, lifecycle, runner, scalability, macos]
evidence: >-
  docs/decisions/0083-portable-systemverilog-runtime-scale-uses-authored-cycle-sampling-and-one-shared-staged-lifecycle.md;
  docs/decisions/0084-macos-premain-stalls-retain-guarded-qualification-not-backend-workarounds.md;
  perl/FSM/VIAL/Backend/VerilatorLifecycle.pm;
  perl/FSM/VIAL/Backend/Runner.pm;
  t/1640-vial-runner-capture-limits.t;
  t/1558-vial-verilator-run-integration.t;
  t/1664-vial-verilator-shared-lifecycle.t;
  t/1665-vial-macos-premain-qualification.t;
  t/1666-vial-macos-premain-evidence.t;
  vial/qualification/sv_portable_verilator/macos-premain-qualification-2026-08-24.json;
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md;
  docs/book/src/16dc-vial-portable-verilator-runtime-measurement.md
reverify: >-
  rg -n 'admitted|prepared|tool_verified|compiled|ran|trace_validated|result_produced|assembled|cleaned|content-addressed|workspace-normalized'
  perl/FSM/VIAL/Backend/VerilatorLifecycle.pm
  docs/book/src/16dc-vial-portable-verilator-runtime-measurement.md &&
  prove -Iperl t/1640-vial-runner-capture-limits.t
  t/1664-vial-verilator-shared-lifecycle.t
  t/1666-vial-macos-premain-evidence.t
---

Decision `0083` selects one private caller-sealed
`FSM::VIAL::Backend::VerilatorLifecycle` for both public Runner execution and
process-isolated scale stages. Completed `.17.3.5.3` implements its forward-only
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
Decision `0084` and completed `.17.3.5.3.1` retain that historical failure while
rejecting an unsupported backend workaround. One policy-active concurrent-link
primary reaches first output in 391.195 ms while `syspolicyd` is 49.0% CPU; two
natural no-compiler primaries reach first output in 311.167 and 345.101 ms.
The 1,847,672-byte generated binaries, byte-identical different-path controls,
and fresh minimal C++ controls all carry the same provenance value and valid
linker-created ad-hoc signatures, yet all execute. The exact four-second quiet
primary policy window contains zero `syspolicyd` log events, and `/usr/bin/true`
also passes under the same supervisor. These observations refute each recorded
condition as an individually sufficient deterministic cause; they do not prove
that macOS policy can never participate in an intermittent stall.

The guarded exact lifecycle test traverses every sealed state
with qualified Verilator, assembles 12 public artifacts, and cleans exactly;
the separate guarded AHB runtime-parity watcher passes. The broader public
integration watcher now passes all seven top-level subtests in a natural quiet
condition, including repeated API, CLI, phase-rollover, and direct-drive byte
determinism. The historical failure remains explicit evidence rather than being
erased by this later pass. The guarded watcher executes the primary once,
retains a timeout as failure, collects a read-only delayed stack sample, and
writes only closed host-path-free evidence below a same-device repository root.
It adds no retry, signing/security change, timeout widening, support promise,
or passed-result fabrication.

Active `.17.3.5.4` now owns the next boundary: route the applicable reference,
gate, and qualification repetitions through the common controller and this
sole lifecycle, retaining exact stage identities, raw samples, exclusions,
guards, and cleanup. Nominal record limit/excess shapes remain tool-free, and
activation adds no performance budget, support, capacity, reached-boundary,
parity, or public API claim.

Related: [[vial-architecture-scale-proof]],
[[hial-vial-verification-fixture-architecture]].
