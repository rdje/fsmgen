# Decision 0084: macOS pre-main stalls retain guarded qualification, not backend workarounds

- **Status:** Accepted
- **Date:** 2026-08-24
- **Owner:** `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.3.1`
- **Refines:** [0083](0083-portable-systemverilog-runtime-scale-uses-authored-cycle-sampling-and-one-shared-staged-lifecycle.md)

## Context

Three freshly linked portable-Verilator executables previously completed
process-group creation and `exec` handoff in 3.7-4.1 milliseconds, produced no
output for the fixed 30-second run wall, and were terminated and cleaned
exactly. A read-only sample placed all 2,389 main-thread samples at
`_dyld_start`, before generated `main` or binary-image mapping. Unrelated Rust
link activity, 28.6%-CPU `syspolicyd`, and a separate 30.179-second policy
network timeout were correlated observations, not causal evidence.

The qualification leaf reconstructed the same canonical VIAL/HIAL/emission/
lifecycle route on macOS 26.5.2 build 25F84, Apple M4 Pro, APFS, Verilator
5.046, and Apple clang 21.0.0. A policy-active concurrent-link observation ran
the generated executable successfully while `syspolicyd` moved from 49.0% to
36.2% CPU. Two no-compiler observations also passed. The generated binaries,
their byte-identical different-path controls, and freshly linked minimal C++
controls all carried the same `com.apple.provenance` value and valid linker-
created ad-hoc signatures. `/usr/bin/true` also passed under the same process
supervisor. The exact quiet-primary policy-log window contained zero
`syspolicyd` events. The full public integration watcher then passed all seven
top-level subtests in 167 seconds, including the formerly failing repeated
direct-drive execution and byte-deterministic repeated API/CLI artifacts.

These observations falsify compiler activity, high policy-daemon CPU,
provenance presence, linker-signature integrity, generated executable bytes,
and generated executable path as individually sufficient deterministic causes.
They do not prove that Gatekeeper or another macOS loader dependency can never
participate in the intermittent stall. No repeatable backend defect or safe
backend correction has been identified.

## Decision

Retain the shared lifecycle and public Runner contracts unchanged. Add one
Darwin-only, explicit-guard qualification watcher and one default static
evidence watcher:

1. `t/1665-vial-macos-premain-qualification.t` independently reconstructs the
   canonical route and requires the caller to label either
   `concurrent_link` or `quiet_no_compiler`. It fails closed if the observed
   process census does not match that label.
2. The guarded watcher executes the primary generated binary exactly once.
   It does not retry. A byte-identical different-path binary, a freshly linked
   minimal C++ binary, and `/usr/bin/true` are separate falsification controls,
   not alternate success paths for the primary.
3. The watcher records exact host/OS/tool/process snapshots, monotonic
   spawn/`exec`/first-output/exit timing, generated-binary digest/bytes/mode,
   Mach-O load commands, extended attributes, signature display/verification,
   primary result, controls, cleanup, and an automatic read-only stack sample
   only when the primary remains alive beyond two seconds.
4. Output is new-file-only canonical JSON below the repository-volume
   `.artifacts/qualification/vial-macos-premain/` root. Every ancestor is a
   non-symlink directory on the repository device, records expose only
   repository-relative or normalized paths, and incomplete attempts retain no
   orphaned sample sidecar.
5. A primary timeout remains a failed test while its bounded evidence and
   controls are retained. It cannot be classified as passing by a control.
6. `vial/qualification/sv_portable_verilator/macos-premain-qualification-2026-08-24.json`
   retains the exact historical and controlled projections, raw-record
   digests/bytes, conclusion, non-workaround boundary, and three claim legs.
   `t/1666-vial-macos-premain-evidence.t` verifies that bounded durable record
   by default.

The watcher is host qualification evidence, not a supported-platform promise,
performance budget, capacity result, automatic CI retry, or public interface.
Future evidence that reproduces a safe project-correctable cause requires a
new decision before product behavior changes.

## Rationale

The lifecycle already distinguishes successful `exec` from generated first
output and fails atomically at the correct wall. Changing its deadline,
re-executing the binary, modifying its signature or xattrs, or bypassing macOS
security would hide the observation and weaken both correctness and platform
security. A guarded watcher preserves exact evidence and makes the hypothesis
space reproducible without turning an intermittent host result into invented
backend success.

The paired primary/counterfactual controls are deliberately asymmetric. Only
the primary determines product success. Controls answer narrower causal
questions after the primary outcome is fixed. This preserves honest failure
classification while still distinguishing generated semantics, binary
content/path, fresh linking, process supervision, and host policy context.

## Alternatives rejected

- **Retry the executable.** A later pass would conceal the first failed run and
  produce an unreviewable effective timeout.
- **Widen the 30-second wall.** The observed stall produced no generated
  progress and no evidence supporting a new qualified deadline.
- **Ad-hoc-sign or strip provenance.** The linker already creates a valid
  ad-hoc signature, provenance-bearing controls pass, and changing platform
  metadata would alter the security condition under investigation.
- **Disable or reconfigure Gatekeeper.** This is unsafe, nonportable, and not
  supported by causal evidence.
- **Kill unrelated workloads.** Quiet observations are taken only when the
  read-only census naturally reaches zero.
- **Classify the issue as a Verilator/FSMGEN defect.** The exact generated
  lifecycle, byte-identical copy, fresh minimal binary, and full repeated
  public route all pass under controlled observations; the available evidence
  does not locate a deterministic defect in those layers.
- **Ignore the prior failure.** The `_dyld_start` sample and three exact
  timeouts are retained as real host evidence and remain part of the watcher
  contract.

## Compatibility and evolution

No parser, bridge, ExecutionIR, emitter, lifecycle transition, command,
timeout, capture ceiling, Runner result, artifact graph, support identity,
security setting, executable signature, or public API changes. Default test
runs validate the bounded evidence and skip host execution unless explicitly
guarded. Rollback removes the two watchers, evidence record, and this decision;
it does not alter shipped runtime behavior.

## Claim verification

- **Re-derivation:** the guarded watcher independently reconstructs the
  canonical route and re-derives host, binary, signing, xattr, timing, sample,
  control, and cleanup evidence. The static watcher independently hashes the
  exact producer and validates the bounded evidence schema.
- **Falsification:** policy-active concurrent-link, two quiet no-compiler,
  byte-identical different-path, freshly linked minimal C++, platform-signed
  `true`, exact policy-log-window, and full repeated public-integration
  controls challenge the candidate causes without changing the primary result.
- **Durability:** the guarded/static watchers, bounded qualification record,
  this decision, owning task-tree, mdBook, Knowledge Map, and work-unit Git
  commit retain the selected boundary and exact evidence projections.
