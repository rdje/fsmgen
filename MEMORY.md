# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: none; `.17.2.7.3`, `.17.2.7`, and `.17.2` are complete.
- next_action: activate `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3`
  measurement as a separate docs-only slice from the clean implementation
  commit.
- in_flight_uncommitted: none.
- in_flight_background: none
- blockers: none.
