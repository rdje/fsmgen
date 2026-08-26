# Decision 0086: Legacy Verilator tests use one bounded test-runtime supervisor

- **Status:** Accepted
- **Date:** 2026-08-26
- **Owner:** `DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.1`
- **Refines:** [0004](0004-simulate-to-catch-codegen-bugs.md), [0084](0084-macos-premain-stalls-retain-guarded-qualification-not-backend-workarounds.md), [0085](0085-darwin-runtime-integration-is-explicit-and-sampling-stays-repository-local.md)

## Context

The RAM-guarded pre-push regression passed through `t/1514`, then
`t/1515-ial2-ahb-two-subordinate-paired-busy-composition.t` waited indefinitely
inside a generated Verilator executable. Its direct
`IPC::Cmd::run(command => [$binary])` call has no timeout. A read-only process
census and one-second sample placed 804/804 main-thread frames at
`_dyld_start`, with a 96-KiB footprint and no image map. This is the retained
Darwin pre-main host boundary from decisions `0084` and `0085`, reached through
legacy test code outside the qualified VIAL lifecycle.

A complete tracked-source census finds 37 literal `verilator --binary`
compile callsites and 37 corresponding generated-runtime callsites across 34
test files. Thirty-six runtime callsites in 33 files use unbounded
`IPC::Cmd::run`. The remaining direct baseline in `t/1559` supplies a
30-second `IPC::Cmd` alarm timeout, but that API does not provide the
repository's verified process-group cleanup evidence. None of the 34 files
has a Darwin qualification boundary before its first applicable tool
discovery. All current callsites preserve a failed command as failed and none
retries.

The public VIAL Runner, guarded lifecycle, macOS diagnostic, and scale
measurement routes are different: they already have explicit opt-in gates,
fixed inner deadlines, bounded capture, whole-process-group cleanup, and
honest first-failure semantics. Reusing the private caller-sealed VIAL
lifecycle from unrelated IAL2/ISF testbenches would violate its authority and
couple verification fixtures to a product-specific artifact/state machine.

## Decision

1. Add one test-only `FSM::Test::VerilatorRuntime` module under `t/lib/`. It
   owns every migrated legacy Verilator version, compile, and generated-binary
   process. It is not a public FSMGEN API and does not replace or modify
   `FSM::VIAL::Backend::VerilatorLifecycle`.
2. The module exposes a pure Darwin qualification query plus three closed
   stage entrypoints: version, compile, and runtime. Stage defaults reuse the
   already qualified boundaries: 10/120/30-second walls and
   65,536/8,388,608/67,108,864-byte aggregate capture limits respectively.
   Callers cannot widen them.
3. On Darwin, affected tests require exact opt-in
   `FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME=1`. The skip decision occurs before
   version lookup or compile, and every process entrypoint independently
   rejects an unqualified Darwin call before `fork`/`exec`. Non-Darwin
   execution remains ordinary and unchanged. Existing VIAL-specific guards
   retain their names and scopes.
4. Supervision accepts only a non-empty scalar argument vector and never
   invokes a shell. Compile calls must name Verilator, contain exactly one
   `--binary`, and provide one repository-local same-volume `--Mdir`. Runtime
   calls must name an existing, executable, non-symlink file within the
   repository volume. Every child changes to the derived repository root
   before `exec`; no persisted absolute path enters documentation or output.
5. A close-on-exec control pipe distinguishes containment/`chdir`/descriptor/
   `exec` failure from ordinary output. Separate nonblocking stdout and stderr
   pipes share one inclusive capture budget. Monotonic evidence distinguishes
   spawn, successful `exec`, first output, and exit.
6. Each process owns a new process group. Timeout, capture overflow, signal,
   surviving descendants, or interrupted handoff sends TERM to the complete
   group, escalates to KILL after a fixed grace interval, reaps the leader,
   and verifies the group is gone. A timeout, limit, nonzero exit, signal,
   exec failure, containment failure, or cleanup failure remains failed.
   There is no retry or alternate success path.
7. The result is one closed, versioned hash with separate stdout/stderr,
   status, exit/signal/timeout/limit/exec fields, selected bounds, monotonic
   timing, and cleanup evidence. The helper does not mutate the caller's
   environment. Affected tests explicitly activate the existing project-local
   test-temp contract before constructing workspaces.
8. Migrate the exact 34-file audit set recorded in the owning task. Preserve
   each generated HDL, testbench, tool arguments, plusargs, assertions, output
   oracle, and failure classification. Existing guarded VIAL lifecycle and
   qualification paths remain unchanged.
9. Add one focused helper/census watcher. It exercises invalid invocation,
   Darwin guard ordering, environment preservation, timeout with a descendant,
   TERM/KILL cleanup, output overflow, nonzero/signal/exec failures, and
   success without retry. It scans all tracked tests and rejects any new
   literal Verilator binary compile or generated `V...` launch through
   `IPC::Cmd`, `system`, shell execution, or another unregistered direct path.

## Rationale

Simulation is essential because lint and synthesis cannot prove the runtime
control-flow behavior these fixtures target. The solution is therefore not to
delete the tests; it is to make their host execution deterministic. A
test-only supervisor keeps the IAL2/ISF fixtures independent from VIAL's
private lifecycle while applying the same mature deadline, capture, handoff,
and process-containment principles.

The platform guard and supervisor solve different failures. The guard keeps a
known Darwin loader condition out of standard regression; the supervisor
ensures any explicitly qualified or non-Darwin execution has a finite,
truthful outcome and cannot strand descendants. Enforcing both in the helper
means a missed caller-side TAP skip still fails closed before tool discovery.

## Alternatives rejected

- **Patch only `t/1515`.** The identical unsafe pattern exists throughout the
  legacy runtime suite and would merely move the next indefinite stop.
- **Use only `IPC::Cmd`'s `timeout` option.** Its installed documentation
  describes an `alarm()` timeout; it does not provide the closed process-group,
  capture, handoff, and cleanup evidence required here.
- **Borrow the private VIAL lifecycle.** It admits canonical VIAL ExecutionIR,
  emission, artifact, and caller identities that these handwritten harnesses
  do not possess.
- **Retry or accept a later control.** That would hide the first failure.
- **Disable runtime simulation on every platform.** That would discard the
  runtime proof selected by decision `0004`; only standard Darwin execution is
  made explicit.
- **Widen the deadline or change macOS security/signing state.** Neither is
  supported by causal evidence and both would weaken the qualified boundary.

## Claim verification

- **Re-derivation:** count literal `verilator --binary` process callsites and
  their source files directly from tracked `t/*.t`; inspect each selected
  subtest for helper, timeout, platform guard, cleanup, and result handling.
- **Falsification:** independently count direct generated-binary
  `IPC::Cmd::run` callsites, add the separately bounded `t/1559` baseline, and
  require exact file-set/count equality with the compile census; separately
  enumerate the already guarded VIAL tool paths so they are not misclassified.
- **Durability:** retain the exact inventory in the owning task, this decision,
  a Knowledge Map card, the mdBook boundary, the focused source watcher, and
  the work-unit Git commits. The watcher recomputes the unsafe-callsite census
  on every focused/full gate after implementation.
