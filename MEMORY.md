# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.8.17`
  (`pending`; fixed Rust sequence-budget qualification)
- next_action: After the .8.16 evidence commit, qualify the larger fixed Rust
  sequence budget and independently verify unchanged invocation/cleanup reserves.
- in_flight_uncommitted: none after the .8.16 observation commit workflow.
- in_flight_background: none; sequence, original results, policy and cleanup consumed.
- blockers: Startup causal repair, parent wire/runtime qualification,
  full CI and push remain gated; controlled engineering needs no authentication.
