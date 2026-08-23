# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.3.2.2`.
- next_action: commit the verified bind-plan/random hot-path repair, archive the
  incompatible 22-report prefix under its exact revision, prove the clean
  revision, then restart the exact execution/checking matrix.
- in_flight_uncommitted: none.
- in_flight_background: none
- blockers: none.
