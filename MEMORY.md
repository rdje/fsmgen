# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.8.15`
  (`pending`; longer-lived Rust capture selection)
- next_action: After the .8.14 evidence commit, qualify the fixed Rust-only
  observed-candidate allowance and its independent counterexamples.
- in_flight_uncommitted: none after the .8.14 evidence commit workflow.
- in_flight_background: none; original, sampler, collector and cleanup consumed.
- blockers: Startup causal repair, parent wire/runtime qualification,
  full CI and push remain gated; controlled engineering needs no authentication.
