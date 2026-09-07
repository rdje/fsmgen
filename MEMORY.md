# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.6.2`
  (`done`; verified bounded fixture harness awaiting commit workflow)
- next_action: Complete this slice's staged doctrine/commit workflow, then inspect the
  still-blocked startup/neutral-verifier frontier and select only an evidence-backed next action.
- in_flight_uncommitted: none after this verified fixture-harness commit workflow.
- in_flight_background: none after focused tests and book build are consumed.
- blockers: Startup causal repair, wire qualification, nested containment, complete CI
  and push remain open. Original failed/interrupted results and safety limits remain binding.
