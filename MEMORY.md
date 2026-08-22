# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.7.2.2`
- next_action: write the honest RED bridge/binder watcher, then implement the
  caller-sealed revision-2 bridge and exact ExecutionIR admission.
- in_flight_uncommitted: none.
- in_flight_background: none
- blockers: none; the director authorized decision 0077's separate revision-2
  balanced qualification route.
