# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5`
- next_action: from the clean decision-`0083` selection, activate proposed
  child `.17.3.5.2` and implement its authored 10,000/15,000-record portable
  runtime materialization and versioned structural oracle.
- in_flight_uncommitted: none.
- in_flight_background: none
- blockers: none.
