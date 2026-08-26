# Decision 0087: Test subprocesses use one shared mechanism behind sealed policy adapters

- **Status:** Accepted
- **Date:** 2026-08-26
- **Owner:** `DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.3.1`
- **Refines:** [0022](0022-project-data-locality-and-same-volume-storage.md), [0026](0026-task-acceptance-uses-project-declared-evidence-registries.md), [0086](0086-legacy-verilator-tests-use-one-bounded-test-runtime-supervisor.md)

## Context

After decision `0086` bounded the legacy generated-Verilator surface, the
RAM-guarded complete-CI suffix reached
`t/1545-task-acceptance-doctrine.t` and stopped in its first fixture. The test
used `IPC::Cmd::run(command => [$checker])` without a deadline or verified
process-tree cleanup. Read-only process inspection found the checker child at
`/usr/bin/env bash`; a one-second sample contained 792 of 792 main-thread
frames at `_dyld_start`, a 96-KiB footprint, and no binary-image map. The
failed chain was terminated and the exact sample completed the required
copy/verify/use/delete locality workflow.

The Verilator helper already contained the process mechanics required for a
sound repair: shell-free argv, separate bounded streams, close-on-exec handoff
evidence, a monotonic wall, an owned process group, and verified TERM/KILL
cleanup. Copying those mechanics into a second helper would create two subtly
divergent implementations. Letting arbitrary tests choose their own bounds,
paths, and commands through a general helper would move policy drift rather
than close it.

A first direct-interpreter probe also established that macOS `/bin/bash` 3.2
cannot execute the current checker under `set -u`: the empty-array expansion
at the registry loop fails immediately. The original environment selects a
newer Bash. The repair must therefore bypass the failed `env` executable
without silently changing the checker's language runtime.

Final combined verification exposed the same hidden boundary inside the
Verilator helper's hostile watcher: a generated `#!/usr/bin/env perl` success
fixture completed exec handoff but produced no output before the sealed
runtime wall. The failure remained failed without retry. Generated watcher
programs must use the canonical already-running Perl interpreter; only the
watcher entrypoint, which `prove` invokes through Perl, may retain the portable
env shebang.

## Decision

1. Extract the process mechanics from `FSM::Test::VerilatorRuntime` into the
   private test-infrastructure module `FSM::Test::ProcessSupervisor`. It owns
   repository/same-volume path admission, scalar argv validation, repository-
   contained cwd, split aggregate-bounded capture, close-on-exec handoff,
   monotonic attribution, one process group, first-failure statuses, and
   verified TERM/KILL cleanup.
2. The low-level mechanism does not select policy. Only narrowly scoped
   policy adapters may call it in `t/lib/FSM/Test/`; a source watcher enforces
   that boundary. `FSM::Test::VerilatorRuntime` remains the sealed adapter for
   decision `0086`, preserving its schema, guard, bounds, validation, and
   behavior.
3. Add `FSM::Test::TaskAcceptanceFixtureRuntime` as the sole subprocess
   adapter for `t/1545`. It admits only workspaces created below
   `.artifacts/tmp/task-acceptance-tests/`, rejects symlink ancestry and other
   repository paths. Git admission is the exact fixture-owned argument shapes:
   quiet initialization; the two local fixture identity settings; baseline or
   `--`-delimited repository-relative adds; and the fixed baseline commit.
   Global configuration, options outside those shapes, absolute/parent paths,
   and every other subcommand fail before process creation.
   Resolve `git` once from absolute inherited `PATH` entries and retain its
   canonical executable, so a later caller-side `PATH` mutation cannot replace
   the admitted tool.
4. Both fixture stages have fixed ten-second walls. Fixture Git capture is
   capped at 1,048,576 aggregate bytes; checker capture is capped at 4,194,304
   aggregate bytes. Callers cannot replace or widen these values. Timeout,
   overflow, nonzero exit, signal, exec failure, surviving descendants, or
   incomplete cleanup remains failed, with no retry.
5. Resolve `bash` once from absolute entries in the inherited `PATH`,
   canonicalize the selected executable, validate it as a regular executable,
   and invoke that exact executable with the repository-local checker path.
   This preserves the caller-selected Bash capability while removing the
   failing `/usr/bin/env` process. Bash is an explicit read-only operating-
   system/toolchain dependency, not project-owned data; all checker inputs,
   outputs, scratch space, and fixture repositories remain on the repository
   volume.
6. Return the closed
   `fsmgen.test.task_acceptance_fixture_result.v1` record with separate
   streams, exit/signal/timeout/limit/exec truth, fixed bounds, monotonic
   timings, and process-group cleanup evidence. Preserve every existing
   `t/1545` fixture, staged-index mutation, expected pass/failure, and output
   assertion.
7. Add a hostile focused watcher that proves the shared mechanism's success
   contract and TERM-resistant descendant cleanup, the fixture adapter's path
   and command rejection, direct Bash handoff, fixed bounds, nonzero truth,
   and exclusive policy-adapter ownership. Its generated programs use the
   canonical running Perl interpreter, and a source assertion prevents an env
   shebang from returning to those fixtures.

## Rationale

Mechanism and policy evolve at different rates. The difficult process code
should have one implementation and one hostile oracle; command admission,
platform guards, time budgets, capture budgets, and schemas belong to small
domain adapters that callers cannot widen. This keeps reuse from becoming an
unbounded general execution API.

Resolving the already-selected Git and Bash binaries once makes command
identity part of the sealed adapter instead of a later mutable-`PATH` choice.
Direct Bash selection is narrower than changing the checker for an obsolete
system shell and safer than retaining an `env` handoff known to stall on the
qualified host. Each process is still bounded, captured, contained, and
failure-preserving. No later result can promote a first failed launch.

## Alternatives rejected

- **Add only an `IPC::Cmd` alarm.** This has no repository-owned proof that
  descendants are terminated and reaped.
- **Duplicate the Verilator supervisor inside `t/1545`.** Two copies would
  drift in cleanup, result, and path semantics.
- **Expose an unrestricted convenience runner to every test.** Callers could
  choose arbitrary commands and widen safety bounds without a reviewable
  policy owner.
- **Invoke `/bin/bash` everywhere.** The exact replay failed because the
  macOS 3.2 shell cannot run the current checker under nounset semantics.
- **Keep `#!/usr/bin/env bash` and retry after a stall.** That retains the
  observed pre-main failure and would erase first-failure truth.
- **Change or weaken the task-acceptance checker.** The checker behavior was
  already correct under its selected Bash; only its unbounded fixture launch
  was defective.

## Claim verification

- **Re-derivation:** inspect the retained process chain and project-local stack
  sample; enumerate both direct `IPC::Cmd` callsites in `t/1545`; inspect the
  shared engine extraction and the two policy adapters; run the exact repaired
  doctrine test.
- **Falsification:** run the adapter once with `/bin/bash` and retain its
  deterministic empty-array failure; exercise inadmissible paths/subcommands,
  nonzero exit, and a TERM-resistant descendant; re-run the full original
  Verilator watcher after extraction.
- **Durability:** retain this decision, the owning task evidence, a Knowledge
  Map card, the mdBook contract, the focused source/hostile watcher, and the
  work-unit Git commits. The watcher recomputes exclusive low-level ownership
  whenever focused or complete regression runs.
