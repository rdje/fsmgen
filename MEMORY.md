# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2`
  (`proposed`; eleven-profile current capture and atomic v2 publication)
- next_action: After the clean `.17.5.1` selection commit, activate `.17.5.2`
  with one selection-only implementation partition before measurement.
- in_flight_uncommitted: none; `.17.5.1` is verified and awaiting its atomic commit.
- in_flight_background: none.
- blockers: none.
