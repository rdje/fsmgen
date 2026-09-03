# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.3`
  (`active`; bounded local and hosted regression-gate CI placement)
- next_action: Query the Knowledge Map, then audit the current local/full and
  hosted CI inventory/cadence authorities and start t1790 RED for missing
  ownership of the explicit regression-gate entrypoints; do not run the real
  gate or full CI in the placement slice.
- in_flight_uncommitted: none.
- in_flight_background: none.
- blockers: none.
