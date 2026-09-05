# Decision 0101: HDL validation shares sealed process supervision

- **Status:** Accepted
- **Date:** 2026-09-05
- **Owner:** `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.2.2.1`
- **Extends:** [0086](0086-legacy-verilator-tests-use-one-bounded-test-runtime-supervisor.md), [0087](0087-test-subprocesses-use-shared-mechanism-and-sealed-policy-adapters.md)

## Context

`FSM::Support::HDLExternalValidation` runs Verilator and Yosys through unbounded
`IPC::Cmd::run`. Clean pre-push qualification stalled before a fixture
executable's `main`; real tools retain the same risk. The reviewed split-stream
`FSM::Test::ProcessSupervisor` has the needed process-group mechanics. The
separate VIAL supervisor owns stronger VIAL-only detached-descendant and outer-worker policy. An alarm lacks cleanup proof, copying the
test engine creates a third implementation, and borrowing VIAL leaks authority.

## Decision

1. Move—not copy—the test supervisor mechanics into internal `FSM::Support::ProcessSupervisor`: scalar argv, repository-volume cwd,
   split bounded capture, exec handoff, monotonic timing, one process group,
   TERM/KILL escalation, leader reaping, and verified group disappearance.
2. Keep `FSM::Test::ProcessSupervisor` as a thin compatibility/authority wrapper. Its adapters, schemas, guards, bounds, paths, results, and callers
   remain exact.
3. Caller-seal process creation to that wrapper and `FSM::Support::HDLExternalValidation`; this is not a public command runner.
4. Seal each HDL step to 120 seconds, 8,388,608 aggregate bytes, repository-
   derived cwd, shell-free argv, and containment label
   `hdl_external_validation_process_group`. Callers cannot widen the policy.
5. Preserve separate stdout/stderr and the success payload. Every supervisor
   failure retains the existing step-failure prefix plus stable status and
   diagnostic; the first failure remains failed without retry.
6. Publish the policy as additive schema-v1 contract metadata and mdBook
   guidance. Leave `FSM::VIAL::Backend::ProcessSupervisor` unchanged.

## Rejected alternatives

- An `IPC::Cmd` alarm lacks capture, descendant, reap, and cleanup proof.
- A copied engine drifts; a VIAL caller leaks private lifecycle authority.
- Retry or alternate-tool success would erase first-failure truth.
- Deterministic test stubs alone do not bound real tool launches.

## Verification and consequences

- **Re-derive:** compare the moved engine with its Git parent; inspect the thin wrapper, caller seal, fixed HDL policy, and absence of direct `IPC::Cmd`.
- **Falsify:** retain the hostile process-tree/caller tests; inject every HDL
  supervisor failure class; run T313's hostile-PATH and installed-tool smoke.
- **Durability:** retain this decision, task evidence, Knowledge Map answer,
  manifest metadata, mdBook guidance, focused watchers, and work-unit commits.

The fixed values are safety ceilings, not performance claims. Changing them requires fresh derivation, public-contract updates, and task-tree evidence.
