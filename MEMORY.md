# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.5.1`
- next_action: reconcile all eight checking-state axes and select bounded
  executable proof for the two one-million-record levels before implementation.
- in_flight_uncommitted: none after the `.17.2.5` activation commit.
- in_flight_background: none
- blockers: none.
