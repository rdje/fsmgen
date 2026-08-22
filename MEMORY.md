# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3`.
- next_action: commit completed exact semantic/bridge matrix `.17.3.2`, then
  activate proposed execution-graph/checking-state measurement `.17.3.3` from
  the clean handoff.
- in_flight_uncommitted: none.
- in_flight_background: none
- blockers: none.
