---
id: vial-verilator-shared-lifecycle
title: One caller-sealed lifecycle owns public and scale Verilator execution
answers:
  - "how will the Runner and scale measurement share Verilator stages?"
  - "how does the shared Verilator lifecycle preserve state and cleanup authority?"
  - "why can portable Verilator time out before generated main on macOS?"
  - "what did the macOS pre-main qualification conclude?"
  - "what work follows completed common-controller portable Verilator measurement?"
  - "how is the portable Verilator runtime matrix published and reloaded?"
date: 2026-08-27
status: current
tags: [vial, verilator, lifecycle, runner, scalability, macos]
evidence: >-
  docs/decisions/0083-portable-systemverilog-runtime-scale-uses-authored-cycle-sampling-and-one-shared-staged-lifecycle.md;
  docs/decisions/0084-macos-premain-stalls-retain-guarded-qualification-not-backend-workarounds.md;
  docs/decisions/0085-darwin-runtime-integration-is-explicit-and-sampling-stays-repository-local.md;
  perl/FSM/VIAL/Backend/VerilatorLifecycle.pm;
  perl/FSM/VIAL/Backend/Runner.pm;
  perl/FSM/VIAL/ArchitectureScalePortableRuntimeMeasurement.pm;
  perl/FSM/VIAL/ArchitectureScalePortableRuntimeMeasurementMatrix.pm;
  t/1640-vial-runner-capture-limits.t;
  t/1558-vial-verilator-run-integration.t;
  t/1664-vial-verilator-shared-lifecycle.t;
  t/1665-vial-macos-premain-qualification.t;
  t/1666-vial-macos-premain-evidence.t;
  t/1667-vial-architecture-scale-portable-runtime-measurement.t;
  t/1670-vial-architecture-scale-portable-runtime-measurement-matrix.t;
  scripts/run_vial_portable_runtime_measurement_matrix.pl;
  vial/qualification/sv_portable_verilator/macos-premain-qualification-2026-08-24.json;
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md;
  docs/book/src/16dc-vial-portable-verilator-runtime-measurement.md
reverify: >-
  rg -n 'admitted|prepared|tool_verified|compiled|ran|trace_validated|result_produced|assembled|cleaned|content-addressed|workspace-normalized'
  perl/FSM/VIAL/Backend/VerilatorLifecycle.pm
  docs/book/src/16dc-vial-portable-verilator-runtime-measurement.md &&
  prove -Iperl t/1640-vial-runner-capture-limits.t
  t/1558-vial-verilator-run-integration.t
  t/1665-vial-macos-premain-qualification.t
  t/1664-vial-verilator-shared-lifecycle.t
  t/1666-vial-macos-premain-evidence.t
  t/1667-vial-architecture-scale-portable-runtime-measurement.t
  t/1670-vial-architecture-scale-portable-runtime-measurement-matrix.t &&
  scripts/run_vial_portable_runtime_measurement_matrix.pl --inventory &&
  FSMGEN_VIAL_PORTABLE_RUNTIME_MEASUREMENT_EXACT=1
  scripts/run_with_ram_guard.sh --
  prove -Iperl t/1667-vial-architecture-scale-portable-runtime-measurement.t
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

Fresh `.17.3.5.3.2` evidence reproduces the moving first-executable failure
without changing the lifecycle: `exec` completes in 3.653 ms, the primary
produces zero bytes and times out at 30 seconds, and all 895 sampled main-thread
frames remain at `_dyld_start` before a binary-image map exists. Its byte-
identical different-path control passes after 10.823397 seconds to first output;
fresh minimal C++ and platform controls also pass. Decision `0085` therefore
makes full Darwin `t/1558` execution explicit through
`FSMGEN_VIAL_DARWIN_RUNTIME_INTEGRATION=1`, while standard Darwin regression
validates the bounded record and non-Darwin integration remains unchanged. A
timeout is never retried or promoted.

The guarded exact lifecycle test traverses every sealed state
with qualified Verilator, assembles 12 public artifacts, and cleans exactly;
the separate guarded AHB runtime-parity watcher passes. The broader public
integration watcher now passes all seven top-level subtests in a natural quiet
condition, including repeated API, CLI, phase-rollover, and direct-drive byte
determinism. The historical failure remains explicit evidence rather than being
erased by this later pass. The guarded watcher executes the primary once,
retains a timeout as failure, collects a read-only delayed stack sample, and
writes only closed host-path-free evidence below a same-device repository root.
The sampler supplies `-file` with that prevalidated repository-derived sidecar;
it never owns project output through `/tmp` or another off-volume default.
It adds no retry, signing/security change, timeout widening, support promise,
or passed-result fabrication.

Completed `.17.3.5.4` routes the applicable reference, gate, and qualification
repetitions through the common controller and this sole lifecycle. The exact
guarded watcher accepts one 274-record reference validation, gate validation
plus three 10,000-record measurements, and qualification validation plus five
15,000-record measurements. Every accepted runtime retains the typed actual
and workspace-normalized commands, complete predecessor chain, 12-artifact
graph, trace/result identities, required raw samples, zero exclusions, and
exact cleanup. Nominal record limit/excess shapes remain tool-free. Compact
assembled state stores a graph descriptor rather than the full graph; a
separate exact watcher proves fresh-process reconstruction and cleanup.
Child `.17.3.5.5.1` implements the producer-derived five-profile immutable
publisher. Separate children publish complete reports before returning compact
entries; aggregate seals require one clean revision/host/tool/guard identity.
The default watcher rejects process, envelope, order, sample, preflight,
collision, and staging drift. Exact capture at `9a534bc93` falsified one MiB
after sealing 75,883/848,468-byte reference/gate reports. Child `.2.1` derives
a 2,121,170-byte workload/repetition projection, rounds to four MiB, and retains
65,536-byte compact IPC. Child `.2.2` owns clean recapture/reload; performance,
support, capacity, parity, IASIM, and API claims remain closed; explicit validation/preflight versus measurement dispatch is repaired before recapture.

Related: [[vial-architecture-scale-proof]],
[[hial-vial-verification-fixture-architecture]].
