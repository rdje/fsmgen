# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.3.2.2`.
- next_action: reproduce and retain the exact `random_attempts/limit_v1`
  correctness-validation stage diagnostic under the real guard, compare it
  with the canonical t/1614 authority, then repair the proven failing layer.
- in_flight_uncommitted: none.
- in_flight_background: none
- blockers: none.
