# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.2.4`
  (`active`; close legacy revision-1 publication byte ceilings)
- next_action: Query the Knowledge Map, then independently census current
  semantic/bridge and execution/checking publication bytes and select
  conservative three-leg ceilings.
- in_flight_uncommitted: none.
- in_flight_background: none.
- blockers: none.
