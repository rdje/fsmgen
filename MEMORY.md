# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.4.2`
- next_action: continue the execution-graph scale ladders — the binding, type, and
  source-map qualification/limit/over-limit levels, then final qualification and
  cleanup.
- in_flight_uncommitted: none
- in_flight_background: none
- blockers: none
