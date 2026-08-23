# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.3.2.1`.
- next_action: enforce the selected total-operation cap from independently
  rederived selected-scenario action counts before operation-graph
  materialization, prove exact excess under the unchanged guard, then resume
  parent `.17.3.3.2` from an empty execution/checking publication namespace.
- in_flight_uncommitted: none.
- in_flight_background: none
- blockers: none.
