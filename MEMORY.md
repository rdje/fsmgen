# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.2.2`
  (`active`; ordered in-memory eleven-profile gate coordination)
- next_action: Start t1787 RED for the absent repository-root-only gate
  coordinator, then admit one complete ordered eleven-profile aggregate in
  memory without publishing it.
- in_flight_uncommitted: none.
- in_flight_background: none.
- blockers: none.
