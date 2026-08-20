# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.5.2`
- next_action: from the clean coverage implementation commit, activate fault
  child `.17.2.5.2.5` as the sole next checking-state implementation leaf.
- in_flight_uncommitted: none after the `.17.2.5.2.4` coverage implementation
  commit; the next slice starts only from that clean boundary.
- in_flight_background: none
- blockers: none.
