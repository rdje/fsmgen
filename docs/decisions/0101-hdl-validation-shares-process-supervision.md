# Decision 0101: HDL validation shares sealed process supervision

- **Status:** Accepted
- **Date:** 2026-09-05
- **Owner:** `.19.2.3.1.2.2.2.2.1`; output-policy amendment `.19.2.3.1.2.2.3.1`
- **Extends:** [0086](0086-legacy-verilator-tests-use-one-bounded-test-runtime-supervisor.md), [0087](0087-test-subprocesses-use-shared-mechanism-and-sealed-policy-adapters.md)

## Context

`FSM::Support::HDLExternalValidation` ran tools through unbounded `IPC::Cmd`;
clean qualification stalled before a fixture `main`. The reviewed test engine
had the needed mechanics, while VIAL's supervisor owns stronger private policy.
The third complete gate then falsified routine output admission: valid T1524
Yosys 0.68 synthesis emitted 46,647,945 bytes normally and zero with `-q`; a quiet absent-source control still exited 1 with its precise `ERROR:`.

## Decision

1. Move—not copy—the test supervisor mechanics into internal `FSM::Support::ProcessSupervisor`: scalar argv, repository-volume cwd,
   split bounded capture, exec handoff, monotonic timing, one process group,
   TERM/KILL escalation, leader reaping, and verified group disappearance.
2. Keep `FSM::Test::ProcessSupervisor` as a thin compatibility/authority wrapper. Its adapters, schemas, guards, bounds, paths, results, and callers
   remain exact.
3. Caller-seal process creation to that wrapper and `FSM::Support::HDLExternalValidation`; this is not a public command runner.
4. Seal each HDL step to 120 seconds, 8,388,608 aggregate bytes, repository cwd,
   shell-free argv, and `hdl_external_validation_process_group`; run Yosys with
   native `-q` before `-p` in default and explicit ABC-mapping modes.
5. Preserve split capture and exact success payloads. Retain at most 65,536
   tool-output bytes per failed stream: first 32,768 plus last 32,768, separated
   by a bounded exact omitted-byte marker. Preserve failure truth and no retry.
6. Publish these values and strategies as additive schema-v1 metadata and mdBook
   guidance. Leave `FSM::VIAL::Backend::ProcessSupervisor` unchanged.

## Rejected alternatives

- An `IPC::Cmd` alarm lacks capture, descendant, reap, and cleanup proof.
- A copied engine drifts; a VIAL caller leaks private lifecycle authority.
- Retry or alternate-tool success would erase first-failure truth.
- Raising capture, spooling unused success logs, universal ring capture, or
  dropping failure output is either brittle, stateful, contract-breaking, or opaque.

## Verification and consequences

- **Re-derive:** compare the moved engine with its parent; regenerate T1524 and stream exact guarded ordinary/quiet Yosys output to `wc -c`.
- **Falsify:** retain hostile process/caller/failure-class tests, require quiet
  absent-source `ERROR:`, and prove excerpt boundary-plus-one in T313.
- **Durability:** retain this decision, task/Knowledge Map, contract/book,
  T313/T1524, doctrine gates, and the work-unit Git chain.

All fixed values are safety ceilings; the T1524 numbers are one-fixture/tool observations, not performance, support, or HIAL/VIAL capacity claims.
